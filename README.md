<p align="center">
<img src="img/banner-build-26.png" alt="Microsoft Build 2026" width="1200"/>
</p>

# [Microsoft Build 2026](https://build.microsoft.com)

## 🔥 LAB513: Build an AI app with Azure SQL Hyperscale, Microsoft Fabric, and Microsoft Foundry

### Session Description

Build an AI-powered FAQ assistant using Azure SQL Database vector search and Retrieval-Augmented Generation (RAG) with Azure OpenAI Service. Use GitHub Copilot to speed T-SQL, mirror data into Microsoft Fabric (OneLake) for analytics, apply governance with Microsoft Purview, and orchestrate the workflow with Microsoft Foundry Agents.

### 🏫 Getting started in a guided session

The lab environment for this lab is a Windows VM with GitHub Copilot CLI, Windows Terminal, Visual Studio Code and an Azure SQL Hyperscale instance pre-provisioned. If you're attending the live session, follow along with the instructor as they guide you through the steps to build an AI app with Azure SQL Hyperscale, Microsoft Fabric, and Microsoft Foundry.

### 🏠 Getting started in your own environment

If you're following these steps at your own pace:

- Create an Azure SQL Database instance with Hyperscale tier.
- Create a project with Microsoft Foundry
- Set up a workspace in Microsoft Fabric tied to a Fabric Capacity.
- Install GitHub Copilot CLI and Visual Studio Code.

Once these prerequisites are in place, you can follow the step-by-step instructions in the [lab overview](docs/Lab/README.md) to build your AI app.

### 🧠 Learning Outcomes

By the end of this lab, you will be able to:

- Build a Retrieval-Augmented Generation workflow over enterprise data using Azure SQL Database vector search and Azure OpenAI Service
- Mirror operational data into Microsoft Fabric OneLake for analytics and downstream AI workflows
- Apply governance with Microsoft Purview and orchestrate the end-to-end experience with Microsoft Foundry Agents

### 💬 Keep Learning with Copilot

Try these prompts with GitHub Copilot to explore the topics from this lab. Open Copilot Chat in Visual Studio Code (`Ctrl+Alt+I` on Windows/Linux, `Cmd+Shift+I` on Mac), paste a prompt, and see what you learn. Try connecting the [Microsoft Learn MCP Server](#-microsoft-learn-mcp-server) for the latest official documentation.

Use these as a starting point — or write your own!

1. Understand semantic search with Azure SQL Database Hyperscale:

    ```text
    Explain how Azure SQL Database Hyperscale uses vector embeddings to retrieve the most relevant FAQ answers for a customer question.
    ```

1. Compare search approaches in T-SQL:

    ```text
    Draft a T-SQL query for Azure SQL Database that compares keyword search with semantic search against dbo.FAQ_Content and dbo.FAQ_Embeddings.
    ```

1. Break down the RAG workflow:

    ```text
    Summarize how Retrieval-Augmented Generation in this lab uses grounded FAQ context to reduce hallucinations.
    ```

1. Go deeper on agent orchestration:

    ```text
    Describe how Microsoft Foundry Agents and MCP work together in this lab to orchestrate FAQ retrieval and grounded responses.
    ```

1. Explore analytics in Microsoft Fabric:

    ```text
    Suggest a Microsoft Fabric report that uses mirrored FAQ_Content data to analyze support trends by category.
    ```

1. Learn when to expose data through MCP:

    ```text
    Explain when you would expose Azure SQL Database through Data API Builder and MCP instead of querying it directly from an application.
    ```

### 💻 Technologies Used

1. [Azure SQL Database Hyperscale](https://learn.microsoft.com/azure/azure-sql/database/service-tier-hyperscale?view=azuresql)
1. [Azure OpenAI Service](https://learn.microsoft.com/azure/ai-foundry/openai/overview)
1. [Microsoft Fabric](https://learn.microsoft.com/fabric/fundamentals/microsoft-fabric-overview)
1. [Microsoft Purview](https://learn.microsoft.com/purview/purview)
1. [Microsoft Foundry](https://learn.microsoft.com/azure/foundry/what-is-foundry)
1. [GitHub Copilot](https://learn.microsoft.com/training/modules/introduction-to-github-copilot/)

### 📚 Resources and Next Steps

| Resource | Description |
|:---------|:------------|
| [https://aka.ms/build26-next-steps](https://aka.ms/build26-next-steps) | Take the next step in your learning journey after Build 2026 |


### 🌟 Microsoft Learn MCP Server

[![Install in Visual Studio Code](https://img.shields.io/badge/Visual_Studio_Code-Install_Microsoft_Docs_MCP-0098FF?style=flat-square&logo=visualstudiocode&logoColor=white)](https://vscode.dev/redirect/mcp/install?name=microsoft.docs.mcp&config=%7B%22type%22%3A%22http%22%2C%22url%22%3A%22https%3A%2F%2Flearn.microsoft.com%2Fapi%2Fmcp%22%7D)

The Microsoft Learn MCP Server is a remote MCP Server that enables clients like GitHub Copilot and other AI agents to bring trusted and up-to-date information directly from Microsoft's official documentation. Get started by using the one-click button above for Visual Studio Code or access the [mcp.json](.vscode/mcp.json) file included in this repo.

For more information, setup instructions for other dev clients, and to post comments and questions, visit our Learn MCP Server GitHub repo at [https://github.com/MicrosoftDocs/MCP](https://github.com/MicrosoftDocs/MCP). Find other MCP Servers to connect your agent to at [https://mcp.azure.com](https://mcp.azure.com).

*Note: When you use the Learn MCP Server, you agree with [Microsoft Learn](https://learn.microsoft.com/en-us/legal/termsofuse) and [Microsoft API Terms](https://learn.microsoft.com/en-us/legal/microsoft-apis/terms-of-use) of Use.*

## Content Owners

<table>
<tr>
    <td align="center"><a href="https://github.com/dikodev">
        <img src="https://github.com/dikodev.png" width="100px;" alt="Someleze Diko"/><br />
        <sub><b>Someleze Diko</b></sub></a><br />
            <a href="https://github.com/dikodev" title="talk">📢</a>
    </td>
  <td align="center"><a href="https://github.com/MatthewCalder-msft">
        <img src="https://github.com/MatthewCalder-msft.png" width="100px;" alt="Matthew Calder"/><br />
        <sub><b>Matthew Calder</b></sub></a><br />
            <a href="https://github.com/MatthewCalder-msft" title="talk">📢</a>
    </td>
</tr>
</table>

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit [Contributor License Agreements](https://cla.opensource.microsoft.com).

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft
trademarks or logos is subject to and must follow
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
