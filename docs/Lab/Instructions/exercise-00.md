# Exercise 00: Prepare the Lab Prerequisites

## Why This Exercise Matters

A hands-on lab works only when every participant starts from exactly the same known state. This exercise ensures that: your cloud database is provisioned and seeded with data, your local tools are installed and working, and your AI services are reachable. Investing a few minutes here prevents you from stopping mid-exercise to troubleshoot a missing tool or an unreachable service.

Think of this exercise as a **preflight checklist**: pilots run one not because they doubt the aircraft, but because a systematic check before takeoff removes all uncertainty so the flight can proceed smoothly.

## What You Will Do

- Connect to your lab VM via RDP
- Confirm your lab credentials and accounts
- Clone the lab repository and verify local tools
- Run the installation scripts to install VS Code extensions and provision Azure SQL Hyperscale
- Verify access to Azure SQL Hyperscale, Microsoft Foundry, and Microsoft Fabric

## What Will Be Ready When You Finish

By the end of this exercise you will have:

| Component | What it does in this lab |
|-----------|-------------------------|
| **Azure SQL Hyperscale** | Stores FAQ content and vector embeddings; serves as the retrieval backbone for the AI assistant |
| **VS Code SQL Server extension** | Lets you run T-SQL queries, browse the database, and connect to Azure SQL directly from your editor |
| **GitHub Copilot** | Accelerates SQL authoring in Exercises 2 and beyond |
| **Python + pip** | Runs the custom MCP server in Exercise 4 |
| **dotnet** | Runs Data API Builder (DAB) in Exercise 6 |
| **devtunnel** | Exposes your local MCP server to the internet in Exercise 4 so Microsoft Foundry can reach it |
| **`C:\LabFiles\sql_mcp_server`** | The pre-written Python MCP server code used in Exercise 4 |
| **`C:\LabFiles\sql-mcp-lab`** | The working folder where you configure and run DAB in Exercise 6 |

> [!Note]
> In the guided lab environment, many of these prerequisites (like the VM, Resource Group, and Microsoft Foundry) are pre-provisioned for you. If you are running the lab in your own self-managed environment, ensure you complete every item in this checklist before continuing.

## Task 1: Connect to the VM and Confirm Credentials

Your workshop organizer provides a **credential sheet** at the start of the session. There is no lab portal to log into — all values you need are printed on that sheet.

1. Locate your credential sheet and confirm it contains the following:

    | Credential | Where it is used in this lab |
    | --- | --- |
    | **VM username and password** | Log into the Windows lab VM via RDP |
    | **Microsoft Entra ID account** | `az login` (Azure CLI to provision Azure SQL), Microsoft Foundry (`https://ai.azure.com/`), Microsoft Fabric (`https://app.fabric.microsoft.com`), and dev tunnel sign-in in Exercise 4 |
    | **Resource group name** | `--server-rg` parameter in the provisioning script |
    | **Microsoft Foundry endpoint** | `--ai-endpoint` parameter in the provisioning script; also used directly in Exercise 3 and Exercise 4 |
    | **Microsoft Foundry API key** | `--ai-key` parameter in the provisioning script; also used directly in Exercise 3 and Exercise 4 |
    | **Your personal GitHub account** | GitHub Copilot sign-in in VS Code — used in Exercise 2 |

    > [!Note]
    > Your SQL server name, database name, SQL admin username, and SQL admin password are **automatically generated** by the provisioning script and saved to `sqldbhyperscale.env`. You do not pre-configure these — they are ready after the script completes in Task 3.

2. Connect to the VM using your local Remote Desktop Protocol (RDP) client with the VM username and password from your credential sheet.
3. Confirm that you can open the following in the VM's browser:
    - Microsoft Foundry at `https://ai.azure.com/`
    - Microsoft Fabric at `https://app.fabric.microsoft.com`

## Task 2: Accept Your GitHub Copilot Invitation and Configure VS Code

> [!Important]
> **Accept your GitHub organization invitation before signing into VS Code with GitHub.** The workshop organizer has invited your personal GitHub account to an organization that provides GitHub Copilot access. If you sign into VS Code before accepting the invitation, Copilot may not activate — and you would need to sign out and back in again to pick up the benefit.

1. **Accept the GitHub invitation (do this first):**
    1. Check your personal email inbox for an invitation from GitHub with a subject similar to *"You've been invited to join [organization name] on GitHub"*.
    1. Open the email and select **View invitation**.
    1. On the GitHub invitation page, select **Accept invitation**.
    1. Confirm the organization appears in your GitHub profile at `https://github.com/settings/organizations`.

    > [!Note]
    > If you do not see the invitation, check your spam folder. Contact the workshop organizer if it has not arrived.

1. Open **Visual Studio Code** from the desktop or start menu.
1. Open a new terminal in VS Code (`Ctrl` + `` ` `` or **Terminal > New Terminal**).
1. Clone the lab repository:

    ```bash
    git clone [https://github.com/YOUR-ORG/YOUR-LAB-REPO.git](https://github.com/YOUR-ORG/YOUR-LAB-REPO.git) C:\LabFiles\lab-repo
    ```
1. Open the cloned folder in VS Code (**File > Open Folder** and select `C:\LabFiles\lab-repo`).

    > [!Tip]
    > **Why these specific tools?**
    > - **Python + pip** — The custom MCP server in Exercise 4 is a Python script. pip installs its dependencies.
    > - **dotnet** — Data API Builder (DAB) in Exercise 6 is a .NET global tool. You install and run it with the `dotnet` CLI.
    > - **devtunnel** — When the MCP server runs on your local machine, Microsoft Foundry (a cloud service) cannot reach `localhost`. Dev Tunnel creates a secure HTTPS forwarding URL that bridges your local process to the public internet.

1. Confirm that the following tools are pre-installed on the lab machine:

    ```powershell
    python --version
    pip --version
    dotnet --version
    devtunnel --version
    ```
    *(If any command fails, install the missing tool before moving to the next task.)*

## Task 3: Run the Environment Installation Scripts

**What these scripts do and why they matter:**

- **`extensions.sh`** installs two VS Code extensions: the MSSQL extension (which lets you browse and query Azure SQL from inside VS Code) and the Azure Resource Groups extension (used for Azure resource visibility). Installing extensions through script ensures every lab participant has identical tooling.
- **`sqldbhyperscale.sh`** creates your dedicated Azure SQL logical server and Hyperscale database, then runs three SQL scripts that: (1) create the `FAQ_Content` and `FAQ_Embeddings` tables, (2) seed FAQ question-and-answer pairs, and (3) generate 1,536-dimension vector embeddings via Azure OpenAI and store them. This is the data foundation that all subsequent exercises depend on.
 - **`extensions.ps1`** installs two VS Code extensions: the MSSQL extension (which lets you browse and query Azure SQL from inside VS Code) and the Azure Resource Groups extension (used for Azure resource visibility). Installing extensions through script ensures every lab participant has identical tooling.
 - **`sqlhyperscale.ps1`** creates your dedicated Azure SQL logical server and Hyperscale database, then runs three SQL scripts that: (1) create the `FAQ_Content` and `FAQ_Embeddings` tables, (2) seed FAQ question-and-answer pairs, and (3) generate 1,536-dimension vector embeddings via Azure Foundry and store them. This is the data foundation that all subsequent exercises depend on.

Before proceeding with the exercises, run the provided installation scripts to ensure the remaining lab resources (VS Code extensions and Azure SQL) are created. 

1. Ensure you are logged into Azure CLI by running the following command in the terminal:

    ```bash
    az login
    ```
    *(Use `az login --use-device-code` if prompted or if the browser doesn't open automatically).*

2. Navigate to the installation scripts directory within your cloned repository (no need to make PowerShell scripts executable on Windows):

    ```powershell
    cd installation-script
    ```
3. Install the required VS Code extensions (`ms-mssql.mssql` and `ms-azuretools.vscode-azureresourcegroups`):

    ```powershell
    .\extensions.ps1
    ```
4. Provision the dedicated Azure SQL logical server and Hyperscale database. Use the values from your credential sheet for the required parameters:

        ```powershell
        .\sqlhyperscale.ps1 \
            --server-rg <YOUR_RESOURCE_GROUP> \
            --ai-endpoint <YOUR_AI_ENDPOINT> \
            --ai-key <YOUR_AI_KEY> \
            --yes
        ```
    > [!Note]
    > Replace `<YOUR_RESOURCE_GROUP>`, `<YOUR_AI_ENDPOINT>`, and `<YOUR_AI_KEY>` with the values from your credential sheet. The script auto-generates the server name, database name, and admin credentials, then saves them to `sqldbhyperscale.env` (and also writes a PowerShell import script `sqldbhyperscale.env.ps1`). Hyperscale creation can take 10–30 minutes depending on region capacity.

## Task 4: Verify Local Files and Working Paths

While the database script is running (it can take 10–30 minutes), use this time to verify your local environment. The two directories below serve specific purposes in later exercises:

- **`C:\LabFiles\sql_mcp_server`** — Contains the pre-written Python MCP server (`server.py`) and its dependency list (`requirements.txt`). You will run this server in Exercise 4 to expose FAQ retrieval as an MCP tool that Foundry Agents can call.
- **`C:\LabFiles\sql-mcp-lab`** — An initially empty working folder. In Exercise 6 you will initialize Data API Builder here and configure it to expose Azure SQL Hyperscale as a standardized MCP endpoint.

While or after the script finishes, confirm that your local environment has the required directories for the upcoming exercises.

1. Verify the VS Code extensions installed successfully:

    ```powershell
    code --list-extensions | Select-String -Pattern 'ms-mssql.mssql|ms-azuretools.vscode-azureresourcegroups'
    ```
2. Confirm that the local MCP sample folder and the empty working folder for Exercise 6 exist. Run the following commands in PowerShell; each returns `True` if the path exists.

    ```powershell
    $items = @(
      'C:\LabFiles\sql_mcp_server',
      'C:\LabFiles\sql_mcp_server\requirements.txt',
      'C:\LabFiles\sql_mcp_server\server.py',
      'C:\LabFiles\sql-mcp-lab'
    )
    $items | ForEach-Object { Write-Output "$_ : $(Test-Path $_)" }
    ```
    *(If you are using a self-managed environment, create `C:\LabFiles\sql-mcp-lab` and place the required MCP server files in `C:\LabFiles\sql_mcp_server` before continuing).*

## Task 5: Verify Azure SQL and Cloud Services

1. **Identify your `{LAB_INSTANCE_ID}`:** Once `sqlhyperscale.ps1` completes, import the generated PowerShell env file and extract your unique instance identifier. It is the auto-generated suffix at the end of your SQL server name.

    ```powershell
    # dot-source the PowerShell env file to load variables into the session
    . .\sqldbhyperscale.env.ps1

    $LAB_INSTANCE_ID = ($env:SQL_SERVER -split '-')[-1]
    Write-Output "Your LAB_INSTANCE_ID: $LAB_INSTANCE_ID"
    ```

    > [!Important]
    > **Write down this value.** You will substitute `{LAB_INSTANCE_ID}` with it throughout the remaining exercises when entering connection strings, naming dev tunnel resources, Fabric workspaces, and Foundry tools.
    >
    > For example, if the script generated `SQL_SERVER=faq-ai-server-a3f2b1`, your `{LAB_INSTANCE_ID}` is `a3f2b1`.

1. **Verify Azure SQL:** Confirm the seeded data by connecting via `sqlcmd` (PowerShell example uses environment variables loaded from the `.ps1` file):

    ```powershell
    sqlcmd -S "tcp:$env:SQL_SERVER.database.windows.net,1433" -d "$env:SQL_DB" -U "$env:SQL_ADMIN" -P "$env:SQL_PASSWORD" -C -Q "SET NOCOUNT ON; SELECT (SELECT COUNT(*) FROM dbo.FAQ_Content) AS faq_count, (SELECT COUNT(*) FROM dbo.FAQ_Embeddings) AS embedding_count;"
    ```
    *(The PowerShell env file you dot-sourced above loaded the correct server name, database name, admin username, and password into `$env:` variables.)*

2. **Verify Microsoft Foundry:** Go back to `https://ai.azure.com/` and confirm you can access the `FAQ-Assistant-project`.
3. **Verify Microsoft Fabric:** Go to `https://app.fabric.microsoft.com` and confirm you can create a new workspace. You will use a workspace named `FAQ-Workspace-{LAB_INSTANCE_ID}` in Exercise 5.

## Task 6: Final Readiness Check

Before moving on, verify that all of the following are true:

- You have accepted the GitHub organization invitation in your email
- You can sign in to Azure with `az login` (for Azure CLI operations)
- Visual Studio Code opens and the SQL Server, GitHub Copilot, and Copilot Chat extensions are available
- `python`, `pip`, `dotnet`, and `devtunnel` run successfully in the terminal
- The installation scripts ran successfully; `sqldbhyperscale.env` exists and Azure SQL Hyperscale is reachable with the FAQ tables
- The lab repository is cloned, and `C:\LabFiles\sql-mcp-lab` and `C:\LabFiles\sql_mcp_server` exist
- Microsoft Foundry opens the `FAQ-Assistant-project`
- Microsoft Fabric is available for workspace creation and mirroring

If every item is ready, continue to the first hands-on exercise.

Next → [1. AI-Enhanced Querying with Azure SQL Hyperscale](../Instructions/exercise-01.md)