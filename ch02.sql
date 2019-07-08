USE AdventureWorks2016CTP3;
SET NOCOUNT ON;
GO

-- Listing 2-1: Dynamic SQL, intro to SQL Injection
DECLARE @CMD NVARCHAR(MAX);
DECLARE @search_criteria NVARCHAR(1000);

SELECT @CMD = 'SELECT * FROM Person.Person
WHERE LastName = ''';
SELECT @search_criteria = 'Smith';
SELECT @CMD = @CMD + @search_criteria;
SELECT @CMD = @CMD + '''';
PRINT @CMD;
EXEC sp_executesql @CMD;
GO

-- Listing 2-2: Use of input value with an apostrophe.
DECLARE @CMD NVARCHAR(MAX);
DECLARE @search_criteria NVARCHAR(1000);

SELECT @CMD = 'SELECT * FROM Person.Person
WHERE LastName = ''';
SELECT @search_criteria = 'O''Brien';
SELECT @CMD = @CMD + @search_criteria;
SELECT @CMD = @CMD + '''';
EXEC sp_executesql @CMD;
GO

-- Listing 2-3: How a hacker can begin to use SQL injection against unsecured dynamic SQL.
DECLARE @CMD NVARCHAR(MAX);
DECLARE @search_criteria NVARCHAR(1000);

SELECT @CMD = 'SELECT * FROM Person.Person
WHERE LastName = ''';
SELECT @search_criteria = 'Smith'' OR 1 = 1 AND '''' = ''';
SELECT @CMD = @CMD + @search_criteria;
SELECT @CMD = @CMD + '''';
EXEC sp_executesql @CMD;
GO

-- Listing 2-4: Dynamic SQL that verifies a user/password combination.
DECLARE @sql_command NVARCHAR(MAX);
DECLARE @id INT = 3;
DECLARE @password NVARCHAR(128) = '';

SELECT @sql_command = '
SELECT
	*
FROM Person.Password
WHERE BusinessEntityID = ' + CAST(@id AS NVARCHAR(25)) + '
AND PasswordHash = ''' + @password + ''''

EXEC (@sql_command)
GO

-- Listing 2-5: Use of UNION ALL via SQL injection to collect additional secure data.
DECLARE @sql_command NVARCHAR(MAX);
DECLARE @id INT = 3;
DECLARE @password NVARCHAR(128) = ''' UNION ALL SELECT * FROM Person.Password WHERE '''' = ''';

SELECT @sql_command = '
SELECT
	*
FROM Person.Password
WHERE BusinessEntityID = ' + CAST(@id AS NVARCHAR(25)) + '
AND PasswordHash = ''' + @password + ''''

EXEC (@sql_command)
GO

-- Listing 2-6: User/password verification statement
DECLARE @sql_command NVARCHAR(MAX);
DECLARE @username NVARCHAR(128) = 'edward';
DECLARE @password NVARCHAR(128) = 'my_password';

SELECT @sql_command = 'SELECT
	*
FROM dbo.password
WHERE username = ''' + @username + ''' AND Password = ''' + @password + '''';

EXEC(@sql_command);
GO

-- Listing 2-7: Closing a dynamic SQL string from an input parameter to probe schema objects.
DECLARE @CMD NVARCHAR(MAX);
DECLARE @search_criteria NVARCHAR(1000);

SELECT @CMD = 'SELECT * FROM Person.Person
WHERE LastName = ''';
SELECT @search_criteria = 'Smith''; SELECT * FROM sys.tables WHERE '''' = '''
SELECT @CMD = @CMD + @search_criteria;
SELECT @CMD = @CMD + '''';
EXEC sp_executesql @CMD;
GO

-- Listing 2-8: Using SQL injection to freely gather password data.
DECLARE @CMD NVARCHAR(MAX);
DECLARE @search_criteria NVARCHAR(1000);

SELECT @CMD = 'SELECT * FROM Person.Person
WHERE LastName = ''';
SELECT @search_criteria = 'Smith''; SELECT * FROM Person.Password WHERE '''' = '''
SELECT @CMD = @CMD + @search_criteria;
SELECT @CMD = @CMD + '''';
EXEC sp_executesql @CMD;
GO

-- Listing 2-9.  Basic input-cleansing search procedure.
CREATE PROCEDURE dbo.search_people
	 (@search_criteria NVARCHAR(1000) = NULL) -- This comes from user input
AS
BEGIN
	SELECT @search_criteria = REPLACE(@search_criteria, '''', '''''');

	DECLARE @CMD NVARCHAR(MAX);

	SELECT @CMD = 'SELECT * FROM Person.Person
	WHERE LastName = ''';
	SELECT @CMD = @CMD + @search_criteria;
	SELECT @CMD = @CMD + '''';
	PRINT @CMD;
	EXEC sp_executesql @CMD;
END
GO

EXEC dbo.search_people 'Smith';
EXEC dbo.search_people 'O''Brien';
EXEC dbo.search_people ''' SELECT * FROM Person.Password; SELECT ''';
GO

-- Listing 2-10.  Input-cleansing search procedure, implemented using QUOTENAME.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'search_people')
	DROP PROCEDURE search_people;
GO

CREATE PROCEDURE dbo.search_people
	 (@search_criteria NVARCHAR(1000) = NULL) -- This comes from user input
AS
BEGIN
	DECLARE @CMD NVARCHAR(MAX);

	SELECT @CMD = 'SELECT * FROM Person.Person
	WHERE LastName = ';
	SELECT @CMD = @CMD + QUOTENAME(@search_criteria, '''');
	PRINT @CMD;
	EXEC sp_executesql @CMD;
END
GO

EXEC dbo.search_people 'Smith';
EXEC dbo.search_people 'O''Brien';
EXEC dbo.search_people ''' SELECT * FROM Person.Password; SELECT ''';
GO

-- Listing 2-11.  Parameterized search procedure.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'search_people')
	DROP PROCEDURE search_people;
GO
CREATE PROCEDURE dbo.search_people
	 (@search_criteria NVARCHAR(50) = NULL) -- This comes from user input
AS
BEGIN
	DECLARE @CMD NVARCHAR(MAX);

	SELECT @CMD = 'SELECT * FROM Person.Person
	WHERE LastName = @search_criteria';
	PRINT @CMD;
	EXEC sp_executesql @CMD, N'@search_criteria NVARCHAR(1000)', @search_criteria;
END
GO

-- Listing 2-12.  Parameterized search procedure using a separate parameter variable.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'search_people')
	DROP PROCEDURE search_people;
GO

CREATE PROCEDURE dbo.search_people
	 (@search_criteria NVARCHAR(1000) = NULL) -- This comes from user input
AS
BEGIN
	DECLARE @CMD NVARCHAR(MAX);
	DECLARE @parameter_list NVARCHAR(MAX) = N'@search_criteria NVARCHAR(1000)';

	SELECT @CMD = 'SELECT * FROM Person.Person
	WHERE LastName = @search_criteria';
	PRINT @CMD;
	EXEC sp_executesql @CMD, @parameter_list, @search_criteria;
END
GO

-- Listing 2-13.  Search procedure with multiple optional parameters.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'search_people')
	DROP PROCEDURE search_people;
GO

CREATE PROCEDURE dbo.search_people
	 (@FirstName NVARCHAR(50) = NULL,
	  @MiddleName NVARCHAR(50) = NULL,
	  @LastName NVARCHAR(50) = NULL,
	  @EmailPromotion INT = NULL)
AS
BEGIN
	DECLARE @CMD NVARCHAR(MAX);
	DECLARE @parameter_list NVARCHAR(MAX) = N'@FirstName NVARCHAR(50), @MiddleName NVARCHAR(50), @LastName NVARCHAR(50), @EmailPromotion INT';

	SELECT @CMD = 'SELECT * FROM Person.Person
	WHERE 1 = 1';
	IF @FirstName IS NOT NULL
		SELECT @CMD = @CMD + '
		AND FirstName = @FirstName'
	IF @MiddleName IS NOT NULL
		SELECT @CMD = @CMD + '
		AND MiddleName = @MiddleName'
	IF @LastName IS NOT NULL
		SELECT @CMD = @CMD + '
		AND LastName = @LastName'
	IF @EmailPromotion IS NOT NULL
		SELECT @CMD = @CMD + '
		AND EmailPromotion = @EmailPromotion';
	PRINT @CMD;
	EXEC sp_executesql @CMD, @parameter_list, @FirstName, @MiddleName, @LastName, @EmailPromotion;
END
GO

EXEC dbo.search_people 'Edward', 'H', 'Johnson', 1
EXEC dbo.search_people 'Edward', NULL, NULL, 1
EXEC dbo.search_people
GO

-- Listing 2-14.  Dynamic table search with no SQL injection protection
DECLARE @table_name SYSNAME = 'ErrorLog';
DECLARE @CMD NVARCHAR(MAX);

SELECT @CMD = 'SELECT * FROM ' + @table_name;
PRINT @CMD;
EXEC sp_executesql @CMD;
GO

-- Listing 2-15.  Dynamic table search with added schema and brackets.
DECLARE @table_name SYSNAME = 'ErrorLog; SELECT * FROM Person.Password WHERE '''' = ''''';
DECLARE @CMD NVARCHAR(MAX);

SELECT @CMD = 'SELECT * FROM [dbo].[' + @table_name + ']';
PRINT @CMD;
EXEC sp_executesql @CMD;
GO

-- Listing 2-16.  Example queries that may be used in blind SQL injection attacks.
IF CURRENT_USER = 'dbo' SELECT 1 ELSE SELECT 0;

IF @@VERSION LIKE '%12.0%' SELECT 1 ELSE SELECT 0;

IF (SELECT COUNT(*) FROM Person.Person WHERE FirstName = 'Edward' AND LastName = 'Pollack') > 0
WAITFOR DELAY '00:00:05'
ELSE
WAITFOR DELAY '00:00:00';

BEGIN TRY
	DECLARE @sql_command NVARCHAR(MAX);
	SELECT @sql_command = 'SELECT COUNT(*) FROM dbo.password;'
	EXEC (@sql_command)
END TRY
BEGIN CATCH
	SELECT 0
END CATCH;
GO