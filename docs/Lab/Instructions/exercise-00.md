# Exercise 00: Prepare the Lab Prerequisites

In this exercise, you verify the accounts, tools, local files, and service access required by the rest of the lab.

You will:

- Confirm that your lab credentials are available
- Verify that the required local tools are installed
- Confirm that the lab files and working folders are available
- Verify access to Azure SQL Hyperscale, Microsoft Foundry, and Microsoft Fabric
- Check the prerequisites for the GPT-5-mini and MCP portions of the lab

By the end of this exercise, you will be ready to move through Exercises 1 through 6 without stopping for missing setup.

> [!Note]
> In the guided lab environment, many of these prerequisites are pre-provisioned for you. If you are running the lab in your own environment, complete every item in this checklist before continuing.

## Task 1: Confirm Your Accounts and Credentials

1. Make sure you have the credentials used throughout the lab.

    | Requirement | Where it is used |
    | --- | --- |
    | Microsoft Entra ID account (`{USERNAME}` and `{ACCESSTOKEN}`) | Azure SQL sign-in, GitHub enterprise sign-in, and dev tunnel sign-in |
    | Azure SQL administrator credentials (`admin-{LAB_INSTANCE_ID}` and `{PASSWORD}`) | Microsoft Fabric mirroring and Data API Builder configuration |
    | Lab instance identifier (`{LAB_INSTANCE_ID}`) | Azure SQL server name, Fabric workspace name, tunnel name, and local configuration values |

1. Confirm that you can open the following experiences in a browser:

    - GitHub enterprise sign-in
    - Microsoft Foundry at `https://ai.azure.com/`
    - Microsoft Fabric at `https://app.fabric.microsoft.com`

1. If you are completing Exercise 3 in your own environment, make sure you also have a GPT-5-mini-compatible chat completions endpoint and an API key available to populate the `@url` and `@headers` values in the sample script.

## Task 2: Verify Local Tools

1. On the lab machine, confirm that the following tools are installed.

    | Tool | Why it is required |
    | --- | --- |
    | Visual Studio Code | Used throughout the lab for SQL, GitHub Copilot, and MCP configuration |
    | SQL Server extension for Visual Studio Code | Required in Exercise 1 to create the Azure SQL connection and run T-SQL |
    | GitHub Copilot and Copilot Chat | Required in Exercise 2 and used again in later exercises |
    | Python 3 and `pip` | Required in Exercise 4 to run the local MCP tool |
    | .NET SDK | Required in Exercise 6 to install and run Data API Builder (https://aka.ms/dotnet/download) |
    | Dev Tunnel CLI (`devtunnel`) | Required in Exercise 4 to expose the local MCP tool to Microsoft Foundry (winget install Microsoft.devtunnel or brew install --cask devtunnel) |
    | Microsoft Edge or another browser | Required for sign-in and browser-based steps in Foundry and Fabric |

1. Run the following commands in a terminal.

    ```powershell
    python --version
    pip --version
    dotnet --version
    devtunnel --version
    ```

1. If any command fails, install the missing tool before moving to Exercise 1.

## Task 3: Confirm Lab Files and Local Working Paths

1. Verify that the local MCP sample folder exists.

    ```text
    C:\LabFiles\sql_mcp_server
    ```

1. Confirm that the folder contains the files referenced later in the lab:

    - `requirements.txt`
    - `server.py`

1. Confirm that you can create or use the working folder referenced in Exercise 6.

    ```text
    C:\LabFiles\sql-mcp-lab
    ```

1. Option: Use PowerShell to check the folders and files exist. Run the following commands in PowerShell; each returns True if the path exists.

    ```powershell
    Test-Path 'C:\LabFiles\sql_mcp_server'
    Test-Path 'C:\LabFiles\sql_mcp_server\requirements.txt'
    Test-Path 'C:\LabFiles\sql_mcp_server\server.py'
    Test-Path 'C:\LabFiles\sql-mcp-lab'
    ```

You can also run a single command to report missing items:

    ```powershell
    $items = @(
      'C:\LabFiles\sql_mcp_server',
      'C:\LabFiles\sql_mcp_server\requirements.txt',
      'C:\LabFiles\sql_mcp_server\server.py',
      'C:\LabFiles\sql-mcp-lab'
    )
    $items | ForEach-Object { Write-Output "$_ : $(Test-Path $_)" }
    ```

1. If you are using a self-managed environment, create both folders now and place the required MCP server files in `C:\LabFiles\sql_mcp_server` before continuing.

## Task 4: Verify Azure SQL Prerequisites

1. Confirm that the Azure SQL Hyperscale server and database are available.

    | Setting | Expected value |
    | --- | --- |
    | Server name | `faq-ai-assistant-{LAB_INSTANCE_ID}.database.windows.net` |
    | Database name | `faq-ai-assistant-db` |

1. Confirm that the lab database includes the objects referenced by the exercises:

    - `dbo.FAQ_Content`
    - `dbo.FAQ_Embeddings`
    - `dbo.SearchFAQ`

1. Confirm that the data is already loaded so Exercise 1 can validate counts and run semantic search.

1. If you plan to complete Exercise 3 in your own environment, confirm that Azure SQL is configured to call external REST endpoints for the model invocation step.

## Task 5: Verify Microsoft Foundry and Microsoft Fabric Access

1. Confirm that you can open Microsoft Foundry and access the project used in Exercise 4.

    | Requirement | Expected value |
    | --- | --- |
    | Foundry entry point | `https://ai.azure.com/` |
    | Project name | `FAQ-Assistant-project` |

1. Confirm that you can open Microsoft Fabric and create items in a workspace.

1. Make sure your environment supports the Fabric steps used in Exercise 5:

    - Create a workspace named `Workspace{LAB_INSTANCE_ID}`
    - Create a mirrored Azure SQL Database item
    - Create a semantic model and Power BI report

## Task 6: Final Readiness Check

Before moving on, verify that all of the following are true:

- You can sign in with your Microsoft Entra ID account
- Visual Studio Code opens and has SQL Server, GitHub Copilot, and Copilot Chat available
- `python`, `pip`, `dotnet`, and `devtunnel` run successfully
- `C:\LabFiles\sql_mcp_server` exists with `requirements.txt` and `server.py`
- Azure SQL Hyperscale is available with the FAQ tables and `dbo.SearchFAQ`
- Microsoft Foundry opens the `FAQ-Assistant-project`
- Microsoft Fabric is available for workspace creation and mirroring
- You have the SQL admin password and, if needed, the GPT-5-mini endpoint and API key for Exercise 3

If every item is ready, continue to the first hands-on exercise.

Next → [1. AI-Enhanced Querying with Azure SQL Hyperscale](../Instructions/exercise-01.md)
