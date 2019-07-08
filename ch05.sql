USE AdventureWorks2016CTP3;
SET NOCOUNT ON;
GO

DECLARE @FirstName NVARCHAR(50) = 'Edward';

SELECT
	*
FROM Person.Person
WHERE FirstName = @FirstName;
GO

DECLARE @FirstName NVARCHAR(50) = 'Edward';
GO

SELECT
	*
FROM Person.Person
WHERE FirstName = @FirstName;
GO

CREATE PROCEDURE dbo.get_people
AS
BEGIN
	DECLARE @FirstName NVARCHAR(50) = 'Edward';

	SELECT
		*
	FROM Person.Person
	WHERE FirstName = @FirstName;
END
GO

EXEC dbo.get_people;
SELECT @FirstName;
GO

-- Listing 5-1: Stored procedure illustrating input and output parameters.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'get_people')
BEGIN
	DROP PROCEDURE dbo.get_people;
END
GO
CREATE PROCEDURE dbo.get_people
	@first_name NVARCHAR(50), @person_with_most_entries NVARCHAR(50) OUTPUT
AS
BEGIN
	DECLARE @person_count INT;

	SELECT TOP 1
		@person_with_most_entries = Person.FirstName
	FROM Person.Person
	GROUP BY Person.FirstName
	ORDER BY COUNT(*) DESC;

	SELECT
		*
	FROM Person.Person
	WHERE FirstName = @first_name;

	RETURN @@ROWCOUNT;
END
GO
DECLARE @person_with_most_entries NVARCHAR(50);
DECLARE @person_count INT;

EXEC @person_count = dbo.get_people 'Edward', @person_with_most_entries OUTPUT;

SELECT @person_with_most_entries AS person_with_most_entries;
SELECT @person_count AS person_count
GO

DECLARE @sql_command NVARCHAR(MAX);

SELECT @sql_command = '
DECLARE @FirstName NVARCHAR(50) = ''Edward'';
SELECT
	*
FROM Person.Person
WHERE FirstName = @FirstName;'
EXEC sp_executesql @sql_command;
SELECT @FirstName
GO

-- Listing 5-2: Dynamic SQL: Updating parameters within the command string.
DECLARE @sql_command NVARCHAR(MAX);
DECLARE @parameter_list NVARCHAR(MAX);
DECLARE @first_name NVARCHAR(50) = 'Edward';

SELECT @sql_command = '
SELECT
	*
FROM Person.Person
WHERE FirstName = @first_name;
SELECT @first_name = ''Xavier'';
SELECT @first_name;
'

SELECT @parameter_list = '@first_name NVARCHAR(50)'
EXEC sp_executesql @sql_command, @parameter_list, @first_name;

SELECT @first_name;
GO

-- Listing 5-3: Rewrite of TSQL from listing 5-2, which returns the same results.
DECLARE @sql_command NVARCHAR(MAX);
DECLARE @parameter_list NVARCHAR(MAX);
DECLARE @first_name_calling_sql NVARCHAR(50) = 'Edward';

SELECT @sql_command = '
SELECT
	*
FROM Person.Person
WHERE FirstName = @first_name_within_dynamic_sql;
SELECT @first_name_within_dynamic_sql = ''Xavier'';
SELECT @first_name_within_dynamic_sql;
'

SELECT @parameter_list = '@first_name_within_dynamic_sql NVARCHAR(50)'
EXEC sp_executesql @sql_command, @parameter_list, @first_name_calling_sql;

SELECT @first_name_calling_sql;
GO

-- Listing 5-4: Using OUTPUT to permanently modify a parameter.
DECLARE @sql_command NVARCHAR(MAX);
DECLARE @parameter_list NVARCHAR(MAX);
DECLARE @first_name_calling_sql NVARCHAR(50) = 'Edward';

SELECT @sql_command = '
SELECT
	*
FROM Person.Person
WHERE FirstName = @first_name_within_dynamic_sql;
SELECT @first_name_within_dynamic_sql = ''Xavier'';
SELECT @first_name_within_dynamic_sql;
'

SELECT @parameter_list = '@first_name_within_dynamic_sql NVARCHAR(50) OUTPUT'
EXEC sp_executesql @sql_command, @parameter_list, @first_name_calling_sql OUTPUT;

SELECT @first_name_calling_sql;
GO

-- Listing 5-5: Results of using a table variable within dynamic SQL that is declared outside of it.
DECLARE @sql_command NVARCHAR(MAX);
DECLARE @parameter_list NVARCHAR(MAX);

DECLARE @last_names TABLE (
	last_name NVARCHAR(50));

SELECT @sql_command = '
SELECT DISTINCT
	FirstName
FROM Person.Person
WHERE LastName IN (SELECT last_name FROM @last_names)'

EXEC sp_executesql @sql_command;
GO

-- Listing 5-6: Passing a table variable into dynamic SQL.
CREATE TYPE last_name_table AS TABLE 
	(last_name NVARCHAR(50));
GO

DECLARE @sql_command NVARCHAR(MAX);
DECLARE @parameter_list NVARCHAR(MAX);
DECLARE @first_name_calling_sql NVARCHAR(50) = 'Edward';

DECLARE @last_names AS last_name_table;

INSERT INTO @last_names
	(last_name)
SELECT
	LastName
FROM Person.Person WHERE FirstName = @first_name_calling_sql;

SELECT @sql_command = '
SELECT DISTINCT
	FirstName
FROM Person.Person
WHERE LastName IN (SELECT last_name FROM @last_name_table)
'

SELECT @parameter_list = '@first_name_within_dynamic_sql NVARCHAR(50), @last_name_table last_name_table READONLY'
EXEC sp_executesql @sql_command, @parameter_list, @first_name_calling_sql, @last_names;
GO

-- Listing 5-7: Results of using a temp table within dynamic SQL that is declared outside of it.
DECLARE @sql_command NVARCHAR(MAX);
DECLARE @parameter_list NVARCHAR(MAX);

CREATE TABLE #last_names (
	last_name NVARCHAR(50));

SELECT @sql_command = '
SELECT DISTINCT
	FirstName
FROM Person.Person
WHERE LastName IN (SELECT last_name FROM #last_names)'

EXEC sp_executesql @sql_command;

DROP TABLE #last_names
GO

-- Listing 5-8: Results of modifying a temp table within dynamic SQL.
DECLARE @sql_command NVARCHAR(MAX);
DECLARE @parameter_list NVARCHAR(MAX);

CREATE TABLE #last_names (
	last_name NVARCHAR(50));

INSERT INTO #last_names
	(last_name)
SELECT 'Thomas'

SELECT @sql_command = '
SELECT DISTINCT
	FirstName
FROM Person.Person
WHERE LastName IN (SELECT last_name FROM #last_names);

INSERT INTO #last_names
	(last_name)
SELECT ''Smith'';
'

EXEC sp_executesql @sql_command;

SELECT * FROM #last_names;

DROP TABLE #last_names;
GO

-- Listing 5-9: Results of creating a temp table within dynamic SQL and accessing it later.
DECLARE @sql_command NVARCHAR(MAX);
DECLARE @parameter_list NVARCHAR(MAX);

SELECT @sql_command = '
CREATE TABLE #last_names (
	last_name NVARCHAR(50));

INSERT INTO #last_names
	(last_name)
SELECT ''Thomas'';
'

EXEC sp_executesql @sql_command;

SELECT DISTINCT
	FirstName
FROM Person.Person
WHERE LastName IN (SELECT last_name FROM #last_names);
GO

-- Listing 5-10: Reusing a temp table in subsequent dynamic SQL is also not valid.
DECLARE @sql_command NVARCHAR(MAX);
DECLARE @parameter_list NVARCHAR(MAX);

SELECT @sql_command = '
CREATE TABLE #last_names (
	last_name NVARCHAR(50));

INSERT INTO #last_names
	(last_name)
SELECT ''Thomas'';
'

EXEC sp_executesql @sql_command;

SELECT @sql_command = '
SELECT DISTINCT
	FirstName
FROM Person.Person
WHERE LastName IN (SELECT last_name FROM #last_names);'

EXEC sp_executesql @sql_command;
GO

-- Listing 5-11: Example of global temporary table usage.
DECLARE @sql_command NVARCHAR(MAX);
DECLARE @parameter_list NVARCHAR(MAX);

SELECT @sql_command = '
CREATE TABLE ##last_names (
	last_name NVARCHAR(50));

INSERT INTO ##last_names
	(last_name)
SELECT ''Thomas'';'

EXEC sp_executesql @sql_command;

SELECT @sql_command = '
SELECT DISTINCT
	FirstName
FROM Person.Person
WHERE LastName IN (SELECT last_name FROM ##last_names);'

EXEC sp_executesql @sql_command;

SELECT * FROM ##last_names;
-- DROP TABLE ##last_names;
GO

CREATE TABLE ##last_names (
	last_name NVARCHAR(50));
GO

CREATE DATABASE temp_table_test;
GO
USE temp_table_test;
GO
SELECT
	*
FROM ##last_names;
GO

DROP DATABASE temp_table_test;
GO

EXECUTE AS USER = 'VeryLimitedUser'; 
GO
SELECT
	*
FROM ##last_names;
REVERT; 
GO
DROP TABLE ##last_names;
GO

-- Listing 5-12: Using a permanent table for temporary storage.
CREATE TABLE dbo.last_names_staging
	(last_name NVARCHAR(50) NOT NULL CONSTRAINT PK_last_names_staging PRIMARY KEY CLUSTERED);
DECLARE @sql_command NVARCHAR(MAX);
DECLARE @parameter_list NVARCHAR(MAX);

SELECT @sql_command = '

INSERT INTO dbo.last_names_staging
	(last_name)
SELECT ''Thomas'';'

EXEC sp_executesql @sql_command;

SELECT @sql_command = '
SELECT DISTINCT
	FirstName
FROM Person.Person
WHERE LastName IN (SELECT last_name FROM dbo.last_names_staging);'

EXEC sp_executesql @sql_command;

SELECT * FROM dbo.last_names_staging;
GO

DROP TABLE last_names_staging
GO

-- Listing 5-13: Inserting dynamic SQL output directly into another table.
DECLARE @sql_command NVARCHAR(MAX);
DECLARE @parameter_list NVARCHAR(MAX);

CREATE TABLE #last_names (
	last_name NVARCHAR(50));

SELECT @sql_command = '
SELECT
	LastName
FROM Person.Person
WHERE FirstName = ''Edward'';
'

INSERT INTO #last_names
	(last_name)
EXEC sp_executesql @sql_command;

SELECT
	*
FROM #last_names

DROP TABLE #last_names;
GO

-- Listing 5-14: Using the INSERT…EXEC syntax to collect output from sp_who
CREATE TABLE #sp_who_data
(	
	spid SMALLINT,
	ecid SMALLINT,
	status NCHAR(30),
	loginame NCHAR(128),
	hostname NCHAR(128),
	blk CHAR(5),
	dbname NCHAR(128),
	cmd NCHAR(16),
	request_id INT
)

INSERT INTO #sp_who_data
(spid, ecid, status, loginame, hostname, blk, dbname, cmd, request_id)
EXEC sp_who;

SELECT * FROM #sp_who_data
WHERE dbname = 'AdventureWorks2012'

DROP TABLE #sp_who_data;
GO
