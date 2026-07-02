from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os
import requests
from dotenv import load_dotenv
import logging
import sys

# 1. Konfigurasi Database
load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")

# Logging configuration
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
logger = logging.getLogger("faq_server")
logger.setLevel(LOG_LEVEL)
handler = logging.StreamHandler(sys.stdout)
formatter = logging.Formatter(
    "%(asctime)s %(levelname)s %(name)s %(message)s"
)
handler.setFormatter(formatter)
if not logger.handlers:
    logger.addHandler(handler)
logger.debug("Logging initialized", extra={"LOG_LEVEL": LOG_LEVEL})

engine = create_engine(
    DATABASE_URL,
    pool_pre_ping=True,
    future=True
)
SessionLocal = sessionmaker(bind=engine)

# 2. Inisialisasi FastAPI
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# 3. Manifest Tool
TOOL_MANIFEST = {
    "tools": [
        {
            "name": "ask_faq",
            "title": "Ask FAQ",
            "description": "Search FAQ using Azure SQL Vector Search and answer using Azure OpenAI.",
            "inputSchema": {
                "type": "object",
                "properties": {
                    "question": {
                        "type": "string"
                    }
                },
                "required": [
                    "question"
                ]
            }
        }
    ]
}

# 4. Helper Functions
def search_faq(question: str):
    logger.debug("search_faq called", extra={"question": question})
    db = SessionLocal()
    try:
        sql = text("""
                EXEC dbo.SearchFAQ
                    @user_question=:question
            """)
        logger.debug("Executing DB query", extra={"sql": str(sql)} )
        rows = db.execute(sql, {"question": question}).mappings().all()
        logger.info("DB query returned rows", extra={"count": len(rows)})
        return rows
    except Exception:
        logger.exception("Error while querying FAQ")
        raise
    finally:
        db.close()

def build_context(rows):
    logger.debug("build_context called", extra={"rows_count": len(rows) if rows else 0})
    if not rows:
        logger.debug("No rows found for context")
        return "No relevant FAQ context found."
    blocks = [f"Question: {row['question']}\nAnswer: {row['answer']}" for row in rows]
    context = "\n\n".join(blocks)
    logger.debug("Context built", extra={"context_length": len(context)})
    return context

def generate_answer(question, context):
    prompt = f"""
Use ONLY the context below to answer the question.

Context:
{context}

Question:
{question}

If the answer is not in the context, say you do not know.
"""
    payload = {
        "model": os.getenv("OPENAI_MODEL"),
        "messages": [
            {
                "role": "system",
                "content": "You are a helpful assistant that answers questions by using only approved FAQ context."
            },
            {
                "role": "user",
                "content": prompt
            }
        ],
        "temperature": 1
    }

    headers = {
        "Content-Type": "application/json",
        "api-key": os.getenv("OPENAI_API_KEY")
    }
    try:
        logger.debug("Sending request to OpenAI", extra={"url": os.getenv("OPENAI_URL"), "model": payload["model"]})
        response = requests.post(
            os.getenv("OPENAI_URL"),
            json=payload,
            headers=headers,
            timeout=30
        )
        logger.debug("OpenAI response status", extra={"status_code": response.status_code})
        response.raise_for_status()
        body = response.json()
        answer = body["choices"][0]["message"]["content"]
        logger.info("Generated answer", extra={"answer_length": len(answer)})
        return answer
    except Exception:
        logger.exception("Error while calling OpenAI API")
        raise

# 5. Route MCP
@app.post("/mcp")
async def mcp(request: Request):
    try:
        body = await request.json()
    except Exception:
        logger.exception("Failed to parse JSON body")
        return {
            "jsonrpc": "2.0",
            "id": None,
            "error": {"code": -32700, "message": "Parse error"}
        }
    method = body.get("method")
    request_id = body.get("id")
    logger.info("Received MCP request", extra={"method": method, "id": request_id})

    # Tambahkan blok ini untuk menyambut "handshake" dari Foundry
    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {
                    "tools": {}
                },
                "serverInfo": {
                    "name": "faq-sql-assistant",
                    "version": "1.0.0"
                }
            }
        }
        
    # Foundry terkadang mengirimkan notifikasi setelah initialize sukses
    if method == "notifications/initialized":
        return {}

    if method == "tools/list":
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {
                "tools": TOOL_MANIFEST["tools"]
            }
        }

    if method == "tools/call":
        params = body["params"]
        logger.debug("tools/call params", extra={"params": params})
        if params["name"] == "ask_faq":
            try:
                question = params["arguments"]["question"]
                logger.info("ask_faq called", extra={"question": question})
                rows = search_faq(question)
                context = build_context(rows)
                answer = generate_answer(question, context)

                logger.info("ask_faq completed", extra={"answer_length": len(answer)})
                return {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "result": {
                        "content": [
                            {
                                "type": "text",
                                "text": answer
                            }
                        ]
                    }
                }
            except Exception:
                logger.exception("ask_faq failed")
                return {
                    "jsonrpc": "2.0",
                    "id": request_id,
                    "error": {"code": -32000, "message": "Internal server error"}
                }

    return {
        "jsonrpc": "2.0",
        "id": request_id,
        "error": {
            "code": -32601,
            "message": "Method not found"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)