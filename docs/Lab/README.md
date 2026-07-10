# Introduction - Azure SQL Hyperscale for AI & RAG Workloads

This lab guides you through building a complete AI-powered FAQ assistant using Azure SQL Hyperscale as the intelligent data backbone. You will progress from raw database exploration through AI-enhanced querying, Retrieval-Augmented Generation (RAG), agent orchestration, analytics mirroring, and finally exposing your data to AI agents through a standards-based protocol.

Each exercise builds on the previous one. By the end, you will have a working end-to-end system and a clear mental model of how modern AI applications connect data, retrieval, grounding, and generation.

## Why Azure SQL Hyperscale?

Traditional databases are built for transactions and reporting — they store and retrieve structured data efficiently. Modern AI applications need more: they need to find semantically similar content (not just exact matches), handle large volumes of data without architectural changes, and serve as the grounding layer that prevents AI models from hallucinating.

Azure SQL Hyperscale addresses all of these because it separates compute and storage, enabling:

- **Independent scaling** of compute and storage — scale one without the other
- **Rapid database growth** up to 100 TB — no rearchitecting as data grows
- **Native vector support** — store and query vector embeddings directly in SQL
- **High-throughput retrieval** — serves both transactional and AI workloads from the same database
- **Fast backups and restores** — snapshot-based, near-instant even at large scale

## Key Concept: The Data Foundation for AI

A major challenge with AI language models is **hallucination** — the model confidently produces incorrect answers when it does not have the right information. The solution used throughout this lab is **grounding**: you retrieve real, verified facts from your database and provide them to the model as context before it answers.

This pattern is called **Retrieval-Augmented Generation (RAG)**, and Azure SQL Hyperscale is well-suited to be its data layer because:

- **Vector columns** let you store embeddings alongside your structured content
- **`VECTOR_DISTANCE`** lets SQL perform semantic similarity search natively
- **Stored procedures** encapsulate retrieval logic so the database is the single source of truth
- **`sp_invoke_external_rest_endpoint`** lets SQL call AI APIs directly, closing the loop inside the database

## Lab Architecture

This is the high-level data flow you will build across all exercises:

```text
┌─────────────────────────────────────────────────────────┐
│              Azure SQL Hyperscale                        │
│  dbo.FAQ_Content    +    dbo.FAQ_Embeddings (VECTOR)     │
│       │                        │                        │
│       └──── SearchFAQ SP ──────┘                        │
│              (semantic retrieval)                        │
└───────────────────────┬─────────────────────────────────┘
                        │
          ┌─────────────┼──────────────┐
          ▼             ▼              ▼
    Exercise 3       Exercise 4    Exercise 5
    RAG in SQL    Foundry Agents   Fabric Mirror
    (GPT answer)  (MCP + Agents)  (Analytics)
                        │
                   Exercise 6
                 DAB / SQL MCP
               (Standardized API)
```

## Lab Exercise Progression

Each exercise introduces a new layer of the system:

| Exercise | What you do | Why it matters |
|----------|-------------|----------------|
| [00 – Prerequisites](Instructions/exercise-00.md) | Set up tools, clone the repo, provision Azure SQL | A consistent environment means you can focus on the AI concepts, not troubleshooting setup |
| [01 – Semantic Search](Instructions/exercise-01.md) | Connect to SQL, explore FAQ data, run vector search | You experience firsthand why semantic search finds relevant results that keyword search misses |
| [02 – GitHub Copilot for SQL](Instructions/exercise-02.md) | Use Copilot to generate, explain, and improve SQL | AI accelerates SQL authoring while you remain in control as the expert who validates the output |
| [03 – RAG Workflow](Instructions/exercise-03.md) | Retrieve FAQ context, build a grounded prompt, call GPT | You see how grounding prevents hallucinations — the model only answers from your data |
| [04 – Foundry Agents + MCP](Instructions/exercise-04.md) | Expose retrieval as an MCP tool, wire it to a Foundry Agent | The agent decides when to call the tool — you move from scripted retrieval to autonomous orchestration |
| [05 – Fabric Mirroring](Instructions/exercise-05.md) | Mirror FAQ data into OneLake, build a Power BI report | Analytics workloads are separated from AI workloads without building any ETL pipelines |
| [06 – SQL MCP via DAB](Instructions/exercise-06.md) | Expose Azure SQL through Data API Builder as an MCP server | Any AI agent or Copilot can now query your database through a standardized, secure interface |

## Key Technologies at a Glance

| Technology | Role in this lab |
|------------|------------------|
| **Azure SQL Hyperscale** | Stores FAQ content and vector embeddings; executes semantic search |
| **Azure OpenAI Service** | Generates embeddings and produces grounded AI answers |
| **GitHub Copilot** | Accelerates SQL development; explains and improves T-SQL |
| **Microsoft Foundry Agents** | Orchestrates the FAQ workflow using tool calls |
| **Model Context Protocol (MCP)** | Standard interface for AI agents to call tools and data services |
| **Microsoft Fabric Mirroring** | Replicates operational data into OneLake for analytics — no ETL |
| **Data API Builder (DAB)** | Exposes Azure SQL as a standards-based MCP server with zero custom code |

## Before You Start

If you are running the lab outside the guided environment, complete [Exercise 00: Prepare the Lab Prerequisites](Instructions/exercise-00.md) before starting the hands-on exercises.
