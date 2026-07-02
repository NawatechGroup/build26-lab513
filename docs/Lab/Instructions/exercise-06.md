# Exercise 6: Expose Azure SQL Hyperscale using SQL MCP Server (Data API Builder)

In this exercise, you use SQL MCP Server built into Data API Builder (DAB) to expose Azure SQL Hyperscale as an MCP-compatible tool.

You will:

- Configure Data API Builder for Azure SQL Hyperscale
- Use a prebuilt DAB configuration
- Use a prebuilt MCP configuration for Visual Studio Code
- Start SQL MCP Server locally
- Connect to it from Visual Studio Code
- Query your database through MCP

By the end of this exercise, you will understand how to expose Azure SQL Hyperscale to AI agents by using a standardized MCP layer.

## Architecture Overview

```text
Azure SQL Hyperscale
-> Data API Builder (DAB)
-> SQL MCP Server
-> Visual Studio Code (Copilot Chat)
-> AI grounded on SQL data
```

## Task 1: Install Data API Builder

1. Return to Visual Studio Code and stop the Python server by pressing `Ctrl+C` in the terminal window where it is running.
1. Create a working folder.

    ```powershell
    mkdir C:\LabFiles\sql-mcp-lab
    cd C:\LabFiles\sql-mcp-lab
    ```

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

1. Create a new file and select **Open**.

    ```powershell
    code C:\LabFiles\sql-mcp-lab\dab-config.json
    ```

1. Add a DAB configuration that:

- Uses the latest DAB schema
- Connects to Azure SQL Hyperscale by using the `faq-ai-assistant-{LAB_INSTANCE_ID}` server and `faq-ai-assistant-db` database
- Enables both `rest` and `mcp`
- Runs the host in `development` mode
- Exposes `dbo.FAQ_Content` as a read-only entity for MCP use

1. Use a configuration like the following:

    ```json
    {
      "$schema": "https://github.com/Azure/data-api-builder/releases/latest/download/dab.draft.schema.json",
      "data-source": {
        "database-type": "mssql",
        "connection-string": "Server=tcp:faq-ai-assistant-{LAB_INSTANCE_ID}.database.windows.net,1433;Initial Catalog=faq-ai-assistant-db;User ID=admin-{LAB_INSTANCE_ID};Password={PASSWORD};Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
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
          ],
          "mcp": {
            "description": "Approved FAQ content used to answer customer support questions."
          }
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

1. Open a new terminal window.
1. Create the `.vscode` folder and open it.

    ```powershell
    mkdir C:\LabFiles\sql-mcp-lab\.vscode
    code C:\LabFiles\sql-mcp-lab\.vscode
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
    By leveraging MCP tool - Find the number of database records in FAQ_Content
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

You used SQL MCP Server through Data API Builder to turn Azure SQL Hyperscale into an AI-ready, MCP-compatible data service without writing custom APIs.

Congratulations on completing this exercise! You now have a foundational understanding of how to expose Azure SQL Hyperscale to AI agents using standardized protocols, enabling powerful retrieval and grounding capabilities for your applications.
