from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
import os
import requests
from dotenv import load_dotenv
import logging
import sys

# Import FastMCP (MCP helper)
from fastmcp import FastMCP

# 1. Database and logging configuration
load_dotenv()
DATABASE_URL = os.getenv("DATABASE_URL")

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
    future=True,
)
SessionLocal = sessionmaker(bind=engine)

# 2. Initialize FastMCP server
mcp = FastMCP("FAQ SQL Assistant")

# 3. Helper functions (business logic)

def search_faq(question: str):
    """Execute the stored procedure to retrieve relevant FAQ rows.

    Returns a list of mapping results from the database.
    """
    logger.debug("search_faq called", extra={"question": question})
    db = SessionLocal()
    try:
        sql = text("""
                EXEC dbo.SearchFAQ
                    @user_question=:question
            """)
        logger.debug("Executing DB query", extra={"sql": str(sql)})
        rows = db.execute(sql, {"question": question}).mappings().all()
        logger.info("DB query returned rows", extra={"count": len(rows)})
        return rows
    except Exception:
        logger.exception("Error while querying FAQ")
        raise
    finally:
        db.close()

def build_context(rows):
    """Build a text context from DB rows for the model prompt.

    Each row becomes a short Q/A block. Returns a single string.
    """
    logger.debug("build_context called", extra={"rows_count": len(rows) if rows else 0})
    if not rows:
        logger.debug("No rows found for context")
        return "No relevant FAQ context found."
    blocks = [f"Question: {row['question']}\nAnswer: {row['answer']}" for row in rows]
    context = "\n\n".join(blocks)
    logger.debug("Context built", extra={"context_length": len(context)})
    return context

def generate_answer(question: str, context: str):
    """Call the model endpoint with the assembled prompt and return the answer text."""
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
            timeout=30,
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

# 4. Tool declaration using decorator
@mcp.tool()
def ask_faq(question: str) -> str:
    """Tool entrypoint: search DB, build context, call model, return answer.

    Returns a string answer or an error message in Indonesian when exceptions occur.
    """
    try:
        logger.info("ask_faq called", extra={"question": question})
        rows = search_faq(question)
        context = build_context(rows)
        answer = generate_answer(question, context)
        logger.info("ask_faq completed", extra={"answer_length": len(answer)})
        return answer
    except Exception as e:
        logger.exception("ask_faq failed")
        return f"Terjadi kesalahan internal server: {str(e)}"

# 5. Run the server
if __name__ == "__main__":
    mcp.run(
        transport="http", 
        host="0.0.0.0", 
        port=8000,
    )