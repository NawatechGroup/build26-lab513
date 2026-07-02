# SQL MCP Server (minimal)

This is a minimal local MCP server used by the lab to expose FAQ retrieval to Microsoft Foundry agents.

Quick start

1. Create a Python venv and activate it:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

2. Install dependencies:

```powershell
pip install -r requirements.txt
```

3. Copy `.env.example` to `.env` and set `DATABASE_URL` to connect to your lab database.

4. Run the server:

```powershell
python server.py
```

The server listens on port 8000 and exposes a minimal MCP POST endpoint at `/mcp` that supports the `search_faq` tool with a JSON body:

```json
{ "name": "search_faq", "args": { "query": "damaged" } }
```

The response format is:

```json
{ "result": [ { "faq_id": 1, "question": "...", "answer": "..." } ] }
```

Use `devtunnel` to expose the server publicly for Foundry as described in the lab instructions.
