# Exercise 6: Expose Azure SQL Hyperscale using SQL MCP Server (Data API Builder)

## Why This Exercise Matters

In Exercise 4, you exposed Azure SQL to an AI agent by writing a **custom Python MCP server**. That gave you full control: you could implement any logic, call any stored procedure, and shape the output exactly as needed. But custom code has a cost — it must be written, maintained, secured, deployed, and updated as the schema changes.

**Data API Builder (DAB)** takes a different approach: you describe your database entities in a JSON configuration file, and DAB automatically generates a REST API *and* an MCP server with no custom code. It handles pagination, filtering, authentication, and protocol details for you.

> **When to use DAB versus a custom MCP server:**
>
> | Scenario | Recommended approach |
> |----------|---------------------|
> | Expose tables and views for read/write access with standard filtering | **DAB** — zero code, maintainable config |
> | Run complex stored procedures with custom business logic | **Custom MCP server** — full control |
> | Prototype quickly for demos and POCs | **DAB** — fastest path to an MCP endpoint |
> | Need custom authentication or transformation logic | **Custom MCP server** |
> | Schema changes frequently | **DAB** — update the config, no code changes |

This exercise shows you the DAB path. After completing it, you will understand both approaches and be able to choose the right one for any project.

## Architecture Overview

```text
Azure SQL Hyperscale
        |
        | (no custom code — JSON config only)
        v
  Data API Builder
  - REST API (optional)
  - MCP Server (built-in)
        |
  Visual Studio Code
  (Copilot Chat as MCP client)
        |
  AI queries FAQ data directly through MCP
```

## What You Will Do

- Configure Data API Builder for Azure SQL Hyperscale
- Use a prebuilt DAB configuration
- Use a prebuilt MCP configuration for Visual Studio Code
- Start SQL MCP Server locally
- Connect to it from Visual Studio Code
- Query your database through MCP

## Task 1: Install Data API Builder

**What is Data API Builder?** DAB is a .NET-based open-source tool from Microsoft that takes a JSON configuration file describing your database and automatically exposes it as a REST API and (since version 1.7) as an MCP server. It runs as a local process, a Docker container, or a deployed Azure service.

You install it as a **.NET local tool** — a tool manifest (`dotnet new tool-manifest`) locks the version to this project, so anyone who clones the repo gets the same version with `dotnet tool restore`.

1. Return to Visual Studio Code and stop the Python server by pressing `Ctrl+C` in the terminal window where it is running.
1. Create a working folder and open it in Visual Studio Code.

    ```powershell
    mkdir C:\LabFiles\sql-mcp-lab
    cd C:\LabFiles\sql-mcp-lab
    ```

    ```powershell
    code -r C:\LabFiles\sql-mcp-lab
    ```

    > [!Note]
    > The `-r` flag reuses the current VS Code window. Once the folder opens, reopen a terminal inside VS Code (`Ctrl` + `` ` ``) and navigate back to `C:\LabFiles\sql-mcp-lab` before continuing.

1. Initialize a tool manifest.

    ```powershell
    dotnet new tool-manifest
    ```

1. Install DAB.

    ```powershell
    dotnet tool install microsoft.dataapibuilder
    ```

1. Verify the installation.

    ```powershell
    dotnet tool run dab --version
    ```

1. Ensure the version is `1.7` or later.

## Task 2: Create the DAB Configuration

**How the DAB config works:** The configuration file has three main sections:

- **`data-source`** — Specifies the database type and connection string. DAB uses this to connect and introspect the schema.
- **`runtime`** — Toggles REST and MCP endpoints. Setting `"mcp": { "enabled": true }` is all it takes to activate the MCP server. The `development` host mode adds debug logging and relaxes some CORS rules, which is appropriate for local development.
- **`entities`** — Maps database objects (tables, views, stored procedures) to API endpoints. Each entity specifies the source object, the primary key, and which roles can perform which actions. Here, `anonymous` users get `read` access only — they cannot insert, update, or delete.

> **Why `faqContent` and not `FAQ_Content`?** DAB entity names become part of the API and MCP tool names. Camel case (`faqContent`) is a convention for JSON-based APIs. The underlying SQL table is still `dbo.FAQ_Content` — the mapping is explicit in the `source.object` field.

1. Create a new file and select **Open**.

    ```powershell
    code dab-config.json
    ```

1. Add a DAB configuration that:

- Uses the latest DAB schema
- Connects to Azure SQL Hyperscale by using the `faq-ai-server-{LAB_INSTANCE_ID}` server and `faq-ai-assistant-db-{LAB_INSTANCE_ID}` database
- Enables both `rest` and `mcp`
- Runs the host in `development` mode
- Exposes `dbo.FAQ_Content` as a read-only entity for MCP use

1. Use a configuration like the following. Replace `{LAB_INSTANCE_ID}` with your value from Exercise 0, and `{SQL_PASSWORD}` with the `SQL_PASSWORD` value from `sqldbhyperscale.env`.

    ```json
    {
      "$schema": "https://github.com/Azure/data-api-builder/releases/latest/download/dab.draft.schema.json",
      "data-source": {
        "database-type": "mssql",
        "connection-string": "Server=tcp:faq-ai-server-{LAB_INSTANCE_ID}.database.windows.net,1433;Initial Catalog=faq-ai-assistant-db-{LAB_INSTANCE_ID};User ID=adminuser;Password={SQL_PASSWORD};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
      },
      "runtime": {
        "rest": {
          "enabled": true
        },
        "mcp": {
          "enabled": true
        },
        "host": {
          "mode": "development"
        }
      },
      "entities": {
        "faqContent": {
          "source": {
            "object": "dbo.FAQ_Content",
            "type": "table"
          },
          "primary-key": ["faq_id"],
          "permissions": [
            {
              "role": "anonymous",
              "actions": ["read"]
            }
          ]
        }
      }
    }
    ```

1. Save the file.

1. This configuration:

    - Connects to Azure SQL Hyperscale
    - Exposes `FAQ_Content` as an MCP-readable entity
    - Enables the MCP server inside DAB
    - Restricts access to read-only operations

## Task 3: Start SQL MCP Server

1. Run the server.

    ```powershell
    dotnet tool run dab start --config dab-config.json
    ```

1. Verify the output and the expected result should be:

    ```text
    Server started successfully
    MCP enabled
    ```

1. Keep this terminal running.

## Task 4: Add MCP Configuration for Visual Studio Code

**What this `mcp.json` does:** VS Code reads `.vscode/mcp.json` to discover MCP servers. Instead of running DAB separately and then pointing VS Code at it, this configuration tells VS Code to launch DAB automatically (using `stdio` transport) when Copilot Chat needs to call MCP tools. The `--mcp-stdio` flag switches DAB into stdio MCP mode — it reads JSON-RPC messages from stdin and writes responses to stdout, which is exactly how VS Code's built-in MCP client communicates.

This `stdio` transport is simpler than the HTTP tunnel approach from Exercise 4 because everything runs locally — VS Code and DAB are on the same machine, so no public URL is needed.

1. Open a new terminal window.
1. Create the `.vscode` folder and open a new file for the MCP configuration.

    ```powershell
    mkdir .vscode
    code .vscode\mcp.json
    ```

1. Add the following content to the `mcp.json` file.

    ```json
    {
      "servers": {
        "sql-mcp-server": {
          "type": "stdio",
          "command": "dotnet",
          "args": [
            "tool",
            "run",
            "dab",
            "start",
            "--mcp-stdio",
            "role:anonymous",
            "--LogLevel",
            "None",
            "--config",
            "${workspaceFolder}/dab-config.json"
          ]
        }
      }
    }
    ```

1. Save the file.

1. This configuration:

    - Launches SQL MCP Server automatically
    - Connects Visual Studio Code to DAB and Azure SQL Hyperscale
    - Avoids manual server wiring

## Task 5: Discover MCP Tools

**What you will see:** DAB exposes each entity as a named MCP tool with a generated description and input schema. Copilot Chat reads those descriptions to understand what the tool does and when to call it. This is the MCP discovery mechanism in action — no hardcoded tool names in the prompt, just the model reading tool metadata and deciding how to use them.

1. In the Visual Studio Code chat pane, start a new chat.
1. Add `mcp.json` as context by selecting it.
1. Enter the following prompt:

    ```text
    What tools are available?
    ```

1. Expected result:

    - The MCP server is invoked
    - Tools are discovered
    - The FAQ entity is visible

## Task 6: Query Azure SQL through MCP

1. Ask the following question in chat:

    ```text
    By leveraging SQL Server MCP tool - Find the number of database records in FAQ_Content
    ```

> [!Note]
> If you see a permission prompt, select `Allow in this Session`.

1. Expected behavior:

    - Visual Studio Code calls MCP
    - MCP calls Azure SQL Hyperscale
    - FAQ rows are returned
    - The response is grounded in database results

1. Try additional prompts:

    ```text
    Find FAQ entries related to damaged products.
    Show me the different categories that exist in the faqContent table.
    ```

### Task 6.1 Troubleshooting

1. If the flow does not work:

    - Ensure DAB is running
    - Check the `dab-config.json` connection string
    - Restart Visual Studio Code
    - Confirm Copilot Chat is enabled
    - Ensure the DAB version is 1.7 or later

## Key Takeaway

You used Data API Builder to turn Azure SQL Hyperscale into an AI-ready, MCP-compatible data service **without writing a single line of application code**. The entire integration is a JSON configuration file.

Comparing the two approaches you have now used:

| | Exercise 4 (Custom Python MCP) | Exercise 6 (DAB MCP) |
|--|--------------------------------|---------------------|
| **Code required** | Python server + SQL logic | JSON config only |
| **Flexibility** | Full — any stored proc, any logic | Entity-based CRUD + filtering |
| **Maintenance** | Update code when schema changes | Update config when schema changes |
| **Best for** | Complex business logic, custom auth | Rapid data exposure, standard CRUD |
| **Protocol** | HTTP (with dev tunnel for cloud agents) | stdio (local) or HTTP (deployed) |

Both are valid and complementary. In a real system you might use DAB for standard entity access and a custom MCP server for complex operations like semantic search.

Congratulations on completing this exercise! You now have a foundational understanding of how to expose Azure SQL Hyperscale to AI agents using standardized protocols, enabling powerful retrieval and grounding capabilities for your applications.
