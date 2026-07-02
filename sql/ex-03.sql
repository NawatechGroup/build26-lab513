-- Execute the SearchFAQ stored procedure with a sample user question
-- EXEC dbo.SearchFAQ @user_question = N'My product arrived damaged';

-- The following code snippet demonstrates how to use the SearchFAQ stored procedure to retrieve relevant FAQ entries based on a user's question, and then constructs a prompt for an AI model using the retrieved context.
-- Question 1
DECLARE @user_question NVARCHAR(1000) = N'My product arrived damaged';
-- Question 2
-- DECLARE @user_question NVARCHAR(1000) = N'How do I track my order?';
-- Question 3
-- DECLARE @user_question NVARCHAR(1000) = N'Can I pay using cryptocurrency?';

DECLARE @context NVARCHAR(MAX);
DECLARE @prompt NVARCHAR(MAX);

CREATE TABLE #searchResults (
    faq_id INT,
    category NVARCHAR(200),
    question NVARCHAR(MAX),
    answer NVARCHAR(MAX)
);

INSERT INTO #searchResults (faq_id, category, question, answer)
EXEC dbo.SearchFAQ @user_question = @user_question;

SELECT @context =
(
    SELECT STRING_AGG(
        CONCAT(
            'Question: ', question, CHAR(10),
            'Answer: ', answer
        ),
        CHAR(10) + CHAR(10)
    )
    FROM #searchResults
);

SET @prompt =
N'Use ONLY the context below to answer the question.
Context:
' + ISNULL(@context, N'No relevant FAQ context found.') + N'
Question:
' + @user_question + N'
If the answer is not in the context, say you do not know.';

SELECT @prompt AS grounded_prompt;

DROP TABLE #searchResults;

-- The following code snippet demonstrates how to call an external AI model endpoint using the constructed prompt, and retrieve the AI-generated answer.
DECLARE @payload NVARCHAR(MAX);
DECLARE @response NVARCHAR(MAX);
DECLARE @headers NVARCHAR(MAX) = N'{"api-key": "<YOUR_AZURE_AI_FOUNDRY_API_KEY>"}';

SET @payload = N'{' +
N'"messages":[' +
N'{"role":"system","content":"You are a helpful assistant that answers questions by using only approved FAQ context."},' +
N'{"role":"user","content":"' + STRING_ESCAPE(@prompt, 'json') + N'"}' +
N'],' +
N'"temperature":1' +
N'}';

EXEC sp_invoke_external_rest_endpoint
    @method = 'POST',
    @url = N'https://<YOUR_AZURE_AI_FOUNDRY_ENDPOINT>/openai/deployments/gpt-5-mini/chat/completions?api-version=2024-10-21',
    @headers = @headers,
    @payload = @payload,
    @response = @response OUTPUT;

SELECT
    @response AS raw_response,
    COALESCE(
        JSON_VALUE(@response, '$.result.choices[0].message.content'),
        JSON_VALUE(@response, '$.choices[0].message.content'),
        JSON_VALUE(@response, '$.output[0].content[0].text'),
        @response
    ) AS ai_answer;