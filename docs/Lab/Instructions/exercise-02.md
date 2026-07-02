# Exercise 2: Accelerate SQL Development with GitHub Copilot

In this exercise, you use GitHub Copilot and Copilot Chat inside Visual Studio Code to accelerate SQL development for the FAQ assistant.

By the end of this exercise, you will be able to:

- Use GitHub Copilot Chat in Visual Studio Code
- Ask Copilot to generate a semantic search query
- Ask Copilot to explain and improve SQL
- Refine AI-generated SQL before using it in the lab

## Task 1: Sign in to GitHub Copilot

1. Open Microsoft Edge and go to the enterprise sign-in page.

    ```text
    https://github.com/enterprises/skillable-events/sso
    ```

1. Select `Continue`, then sign in with your Microsoft Entra ID account.

    | Setting | Value |
    | --- | --- |
    | Username | `{USERNAME}` |
    | TAP | `{ACCESSTOKEN}` |

1. Close the browser tab after signing in.
1. Return to Visual Studio Code and select `Signed out` in the status area.
1. Select `Sign in to use AI Features`.

    ![Screenshot of Visual Studio Code status bar with the Sign in to use AI Features option highlighted](../media/github-sign-in-ai-features.png)

1. Select `Continue with GitHub`, then select `Continue` on the authorization page.

    ![Screenshot of Visual Studio Code with the Continue with GitHub option highlighted](../media/github-authorize.png)

1. Select `Authorize Visual-Studio-Code`, then select `Open`.

## Task 2: Generate a Semantic Search Query

1. Open a new SQL query window by selecting **View** > **Command Palette** > `MS SQL: New Query`.

1. Open Copilot Chat in Visual Studio Code. If the chat pane is not visible, select `View`, then select `Chat`.

    ![Screenshot of Visual Studio Code with the Chat option highlighted in the View menu](../media/github-chat.png)

1. Enter a prompt like the following:

    ```text
    Generate a T-SQL query for Azure SQL that returns the top 3 FAQ items most relevant to a customer question by using dbo.FAQ_Content and dbo.FAQ_Embeddings.
    ```

If you see a permission prompt, select `Allow in this Session`.

![Screenshot of Visual Studio Code with a permission prompt for GitHub Copilot highlighted](../media/allow-in-session.png)

1. Review the SQL returned by Copilot. Do not run it yet check whether it includes:

    - `dbo.FAQ_Content`
    - `dbo.FAQ_Embeddings`
    - A join on `faq_id`
    - `TOP 3`
    - `VECTOR_DISTANCE`

1. Copy the Copilot-generated SQL into your query window or SQL file.
1. Compare the Copilot-generated SQL with the semantic search query from Exercise 1.

    - Look for similarities and differences.
    - Notice whether Copilot used the correct `VECTOR_DISTANCE` argument order.

> [!Important]
> Azure SQL expects the metric as the first argument to `VECTOR_DISTANCE`, followed by the two vector values. If needed, keep the lab's validated query as the final version.

1. Ask Copilot to Explain the Query. In Copilot Chat, enter a prompt like the following:

    ```text
    Explain this SQL query step by step for someone who is new to vector search in Azure SQL.
    ```

1. Review the explanation. Notice how Copilot breaks down:

    - The join between the two tables
    - The similarity calculation
    - Why the results are ordered by vector distance

1. Ask Copilot to Improve Readability. In Copilot Chat, enter a prompt like the following:

    ```text
    Rewrite this query to make it easier to read for a lab demo. Add clean formatting and brief comments.
    ```

1. Copy the improved version into your SQL file.

## Task 3: Ask Copilot for Schema Suggestions

1. In Copilot Chat, enter a prompt like the following:

    ```text
    Review the schema for dbo.FAQ_Content and dbo.FAQ_Embeddings and suggest improvements.
    ```

1. Review the suggestions. Look for ideas such as:

    - Readability and documentation improvements
    - Indexing considerations
    - Separation of content and embeddings
    - Column type suggestions

## Task 4: Ask Copilot to Draft a Stored Procedure

1. In Copilot Chat, enter a prompt like the following:

    ```text
    Generate a stored procedure draft for Azure SQL called dbo.usp_GetTopFaqMatches that returns the most relevant FAQ rows for a user question.
    ```

1. Review the stored procedure returned by Copilot.

> [!Note]
> You do not need to deploy it yet. This step demonstrates how Copilot can accelerate repeatable SQL authoring patterns.

## Task 5: Wrap Up

1. Ask one final prompt.

    ```text
    Summarize in 3 bullet points how GitHub Copilot helped improve SQL development in this exercise.
    ```

1. Review the summary. Copilot should help with:

    - Generating SQL
    - Explaining SQL
    - Refining SQL structure

Next → [3. Implement Retrieval-Augmented Generation (RAG) with Azure SQL Hyperscale](../Instructions/exercise-03.md)
