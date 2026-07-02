-- Retrieve the top 10 rows from the FAQ_Content table
-- SELECT TOP 10 *
-- FROM dbo.FAQ_Content;

-- Retrieve the top 5 rows from the FAQ_Embeddings table
-- SELECT TOP 5 *
-- FROM dbo.FAQ_Embeddings;

-- Count the number of rows in the FAQ_Content table
-- SELECT COUNT(*) AS faq_count
-- FROM dbo.FAQ_Content;

-- Count the number of rows in the FAQ_Embeddings table
-- SELECT COUNT(*) AS embedding_count
-- FROM dbo.FAQ_Embeddings;

-- Execute the SearchFAQ stored procedure with a sample user question
-- EXEC dbo.SearchFAQ @user_question = N'My product arrived damaged';

-- Execute the SearchFAQ stored procedure with another sample user question
-- EXEC dbo.SearchFAQ @user_question = N'Where can I check my delivery status?';

-- Retrieve the top 3 FAQ rows related to delivery status
-- SELECT TOP 3 c.faq_id, c.category, c.question, c.answer
-- FROM dbo.FAQ_Content AS c
-- WHERE c.question LIKE 
-- N'%delivery status%';

-- Execute the SearchFAQ stored procedure with a sample user question
-- EXEC dbo.SearchFAQ @user_question = N'Where can I check my delivery status?';