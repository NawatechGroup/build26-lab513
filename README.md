# Build an AI App with Azure SQL Hyperscale, Microsoft Fabric, and Microsoft Foundry

> **About this fork**
> This repository is forked and adapted from the official [Microsoft Build 2026 LAB513](https://github.com/microsoft/Build26-LAB513-build-an-ai-app-with-azure-sql-hyperscale-microsoft-fabric-foundry) session lab, originally authored by [Someleze Diko](https://github.com/dikodev) and [Matthew Calder](https://github.com/MatthewCalder-msft).
> Adjustments have been made to the lab content, instructions, and supporting files to suit a self-paced or customized delivery context.

## What This Lab Is About

This lab guides you through building a complete, end-to-end AI-powered FAQ assistant — from an empty database to a fully orchestrated agent. The data backbone is Azure SQL Hyperscale. The intelligence is provided by Azure OpenAI Service. GitHub Copilot accelerates development, Microsoft Foundry Agents orchestrate the workflow, and Microsoft Fabric mirrors the data for analytics.

Each exercise introduces a new layer of the system. By the end, you will have a working system and a clear mental model of how modern AI applications connect data, retrieval, grounding, and generation.

## The Core Problem: Hallucination and Grounding

A major challenge with AI language models is **hallucination** — the model confidently produces incorrect answers when it does not have the right information in context. The solution used throughout this lab is **grounding**: you retrieve real, verified facts from your database and supply them to the model as context *before* it generates an answer.

This pattern is called **Retrieval-Augmented Generation (RAG)**:

```text
User question
     │
     ▼
Convert question to vector embedding (Azure OpenAI)
     │
     ▼
Search dbo.FAQ_Embeddings for nearest vectors (VECTOR_DISTANCE)
     │
     ▼
Return matching FAQ content as grounding context
     │
     ▼
Pass context + question to GPT → grounded, accurate answer
```

Because the model only answers from verified database content, hallucinations are dramatically reduced. Every exercise in this lab is built around this principle.

## Why Azure SQL Hyperscale?

Traditional databases are built for transactions and reporting. Modern AI workloads need more: they need to find *semantically similar* content (not just exact matches), handle large data volumes without rearchitecting, and serve as the grounding layer that keeps AI answers accurate.

Azure SQL Hyperscale addresses all of these by separating compute and storage:

| Capability | What it enables |
|---|---|
| **Independent scaling** | Scale compute or storage separately — no rearchitecting |
| **Up to 100 TB storage** | Grow the FAQ corpus without hitting database limits |
| **Native vector columns** | Store embeddings alongside structured content in the same table |
| **`VECTOR_DISTANCE`** | Semantic similarity search runs natively inside SQL |
| **`sp_invoke_external_rest_endpoint`** | SQL can call Azure OpenAI directly — RAG closes inside the database |
| **High-throughput retrieval** | Serves both transactional and AI workloads from the same database |
| **Snapshot-based backups** | Near-instant backup and restore even at large scale |

## Architecture

This is the end-to-end data flow you will build across all exercises:

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

## Key Technologies

| Technology | Role in this lab |
|---|---|
| **Azure SQL Hyperscale** | Stores FAQ content and vector embeddings; executes semantic search |
| **Azure OpenAI Service** | Generates embeddings and produces grounded AI answers |
| **GitHub Copilot** | Accelerates SQL development; explains and improves T-SQL |
| **Microsoft Foundry Agents** | Orchestrates the FAQ workflow using autonomous tool calls |
| **Model Context Protocol (MCP)** | Standard interface for AI agents to call tools and data services |
| **Microsoft Fabric Mirroring** | Replicates operational data into OneLake for analytics — no ETL |
| **Data API Builder (DAB)** | Exposes Azure SQL as a standards-based MCP server with zero custom code |

## Exercise Progression

The exercises are sequential — each one builds directly on the previous. Start from Exercise 00 and work forward.

| Exercise | What you do | What you learn |
|---|---|---|
| [00 – Prerequisites](Lab/Instructions/exercise-00.md) | Set up tools, clone the repo, provision Azure SQL | A consistent environment so you can focus on AI concepts, not troubleshooting |
| [01 – Semantic Search](Lab/Instructions/exercise-01.md) | Connect to SQL, explore FAQ data, run vector search | Why semantic search finds relevant results that keyword search misses |
| [02 – GitHub Copilot for SQL](Lab/Instructions/exercise-02.md) | Use Copilot to generate, explain, and improve T-SQL | How AI accelerates SQL authoring while you stay in control as the expert |
| [03 – RAG Workflow](Lab/Instructions/exercise-03.md) | Retrieve FAQ context, build a grounded prompt, call GPT | How grounding prevents hallucinations — the model only answers from your data |
| [04 – Foundry Agents + MCP](Lab/Instructions/exercise-04.md) | Expose retrieval as an MCP tool, wire it to a Foundry Agent | How the agent decides autonomously when to call the retrieval tool |
| [05 – Fabric Mirroring](Lab/Instructions/exercise-05.md) | Mirror FAQ data into OneLake, build a Power BI report | How analytics workloads can be separated from AI workloads without ETL |
| [06 – SQL MCP via DAB](Lab/Instructions/exercise-06.md) | Expose Azure SQL through Data API Builder as an MCP server | How any AI agent or Copilot can query your database through a standardized, secure interface |

## Learning Outcomes

By the end of this lab, you will be able to:

- Explain the RAG pattern and why grounding prevents AI hallucinations
- Build semantic search over structured enterprise data using Azure SQL native vector support
- Write and improve T-SQL with GitHub Copilot as an AI pair programmer
- Implement a full RAG workflow — from embedding generation to grounded GPT responses — entirely within Azure SQL
- Expose a retrieval tool via MCP and wire it to a Microsoft Foundry Agent for autonomous orchestration
- Mirror operational data into Microsoft Fabric OneLake for analytics without building ETL pipelines
- Publish Azure SQL data as a standards-based MCP server using Data API Builder

## Getting Started

Prerequisites:

- An Azure SQL Database instance (Hyperscale tier)
- A Microsoft Foundry project
- A Microsoft Fabric workspace tied to a Fabric Capacity
- GitHub Copilot and Visual Studio Code

Start with [Exercise 00 – Prerequisites](Lab/Instructions/exercise-00.md) to set up your environment and provision the necessary Azure resources.
