USE AdventureWorks2016CTP3;
SET NOCOUNT ON;
GO

-- Listing 4-1.  Simple stored procedure to demonstrate ownership chaining.
CREATE PROCEDURE dbo.ownership_chaining_example
AS
BEGIN
	SET NOCOUNT ON;
	-- Select the current security context, for reference
	SELECT SUSER_SNAME();
	SELECT COUNT(*) FROM Person.Person;

	DECLARE @sql_command NVARCHAR(MAX);
	SELECT @sql_command = 'SELECT SUSER_SNAME();
	
	SELECT COUNT(*) FROM Person.Person';

	EXEC sp_executesql @sql_command;
END
GO

EXEC dbo.ownership_chaining_example;
GO

CREATE USER VeryLimitedUser WITHOUT LOGIN; 
GO
CREATE ROLE VeryLimitedRole; 
GO
EXEC sys.sp_addrolemember 'VeryLimitedRole', 'VeryLimitedUser'; 
GO

GRANT EXECUTE ON dbo.ownership_chaining_example TO VeryLimitedRole; 
GO

EXECUTE AS USER = 'VeryLimitedUser';
GO
EXEC dbo.ownership_chaining_example;
GO
REVERT;
GO

SELECT SUSER_SNAME() AS SUSER_SNAME, USER_NAME() AS USER_NAME, ORIGINAL_LOGIN() AS ORIGINAL_LOGIN;
GO
EXECUTE AS USER = 'VeryLimitedUser'; 
SELECT SUSER_SNAME() AS SUSER_SNAME, USER_NAME() AS USER_NAME, ORIGINAL_LOGIN() AS ORIGINAL_LOGIN;
GO

REVERT; 
GO
SELECT SUSER_SNAME() AS SUSER_SNAME, USER_NAME() AS USER_NAME, ORIGINAL_LOGIN() AS ORIGINAL_LOGIN;
GO

EXECUTE AS USER = 'VeryLimitedUser' WITH NO REVERT;
GO

REVERT;
GO
EXECUTE AS USER = 'Edward';
GO

-- Listing 4-2.  Stored procedure demonstrating EXECUTE AS OWNER.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'ownership_chaining_example')
BEGIN
	DROP PROCEDURE dbo.ownership_chaining_example;
END
GO

CREATE PROCEDURE dbo.ownership_chaining_example
WITH EXECUTE AS OWNER
AS
BEGIN
	SET NOCOUNT ON;
	-- Select the current security context, for reference
	SELECT SUSER_SNAME() AS security_context_no_dynamic_sql;
	SELECT COUNT(*) AS table_count_no_dynamic_sql FROM Person.Person;

	DECLARE @sql_command NVARCHAR(MAX);
	SELECT @sql_command = 'SELECT SUSER_SNAME() AS security_context_in_dynamic_sql;
	
	SELECT COUNT(*) AS table_count_in_dynamic_sql FROM Person.Person';

	EXEC sp_executesql @sql_command;
END
GO

-- Listing 4-3.  Stored procedure demonstrating EXECUTE AS CALLER.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'ownership_chaining_example')
BEGIN
	DROP PROCEDURE dbo.ownership_chaining_example;
END
GO

CREATE PROCEDURE dbo.ownership_chaining_example
WITH EXECUTE AS CALLER
AS
BEGIN
	SET NOCOUNT ON;
	-- Select the current security context, for reference
	SELECT SUSER_SNAME() AS security_context_no_dynamic_sql;
	SELECT COUNT(*) AS table_count_no_dynamic_sql FROM Person.Person;

	DECLARE @sql_command NVARCHAR(MAX);
	SELECT @sql_command = 'SELECT SUSER_SNAME() AS security_context_in_dynamic_sql;
	
	SELECT COUNT(*) AS table_count_in_dynamic_sql FROM Person.Person';

	EXEC sp_executesql @sql_command;
END
GO

-- Listing 4-4.  Stored procedure embedding a security context change in dynamic SQL.
CREATE LOGIN EdwardJr WITH PASSWORD = 'AntiSemiJoin17', DEFAULT_DATABASE = AdventureWorks2016CTP3;
GO
USE AdventureWorks2016CTP3
GO
CREATE USER EdwardJr FROM LOGIN EdwardJr;
EXEC sp_addrolemember 'db_owner', 'EdwardJr';
GO

IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'ownership_chaining_example')
BEGIN
	DROP PROCEDURE dbo.ownership_chaining_example;
END
GO

CREATE PROCEDURE dbo.ownership_chaining_example
AS
BEGIN
	SET NOCOUNT ON;
	-- Select the current security context, for reference
	SELECT SUSER_SNAME() AS security_context_no_dynamic_sql;
	SELECT COUNT(*) AS table_count_no_dynamic_sql FROM Person.Person;

	DECLARE @sql_command NVARCHAR(MAX);
	SELECT @sql_command = 'EXECUTE AS LOGIN = ''EdwardJr'';
	SELECT SUSER_SNAME() AS security_context_in_dynamic_sql;
	
	SELECT COUNT(*) AS table_count_in_dynamic_sql FROM Person.Person';

	EXEC sp_executesql @sql_command;
END
GO

EXEC dbo.ownership_chaining_example;
GO

GRANT EXECUTE ON dbo.ownership_chaining_example TO VeryLimitedRole; 
EXECUTE AS USER = 'VeryLimitedUser';
EXEC dbo.ownership_chaining_example;
REVERT;
GO
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'search_all_schema')
BEGIN
	DROP PROCEDURE dbo.search_all_schema;
END
GO

-- Listing 4-6.  Schema search stored procedure.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'search_all_schema')
BEGIN
	DROP PROCEDURE dbo.search_all_schema;
END
GO

CREATE PROCEDURE dbo.search_all_schema
	@searchString NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;

	-- This is the string you want to search databases and jobs for.  MSDB, model and any databases named like tempDB will be ignored
	SET @searchString = '%' + @searchString + '%';
	DECLARE @sql NVARCHAR(MAX);
	DECLARE @database_name NVARCHAR(MAX);
	DECLARE @databases TABLE (database_name NVARCHAR(MAX));

	IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '#object_data')
	BEGIN
		DROP TABLE #object_data;
	END

	CREATE TABLE #object_data
	(	database_name NVARCHAR(MAX) NOT NULL,
		schemaname SYSNAME NULL,
		table_name SYSNAME NULL,
		objectname SYSNAME NOT NULL,
		object_type NVARCHAR(MAX) NOT NULL);

	IF EXISTS (SELECT * FROM tempdb.sys.tables WHERE name = '#index_data')
	BEGIN
		DROP TABLE #index_data;
	END

	CREATE TABLE #index_data
	(	database_name NVARCHAR(MAX) NOT NULL,
		schemaname SYSNAME NOT NULL,
		table_name SYSNAME NOT NULL,
		index_name SYSNAME NOT NULL,
		key_column_list NVARCHAR(MAX) NOT NULL,
		include_column_list NVARCHAR(MAX) NOT NULL);

	INSERT INTO @databases
		(database_name)
	SELECT
		name
	FROM sys.databases
	WHERE name NOT IN ('msdb', 'model', 'tempdb')
	AND state_desc <> 'OFFLINE';

	DECLARE DBCURSOR CURSOR FOR SELECT database_name FROM @databases;
	OPEN DBCURSOR;
	FETCH NEXT FROM DBCURSOR INTO @database_name;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @sql = '
		USE [' + @database_name + '];
		-- Tables
		INSERT INTO #object_data
			(database_name, schemaname, table_name, objectname, object_type)
		SELECT
			db_name() AS database_name,
			schemas.name AS schema_name,
			tables.name AS table_name,
			tables.name AS objectname,
			''Table'' AS object_type
		FROM sys.tables
		INNER JOIN sys.schemas
		ON schemas.schema_id = tables.schema_id
		WHERE tables.name LIKE ''' + @searchString + ''';
		-- Columns
		INSERT INTO #object_data
			(database_name, schemaname, table_name, objectname, object_type)
		SELECT
			db_name() AS database_name,
			schemas.name AS schema_name,
			tables.name AS table_name,
			columns.name AS objectname,
			''Column'' AS object_type
		FROM sys.tables
		INNER JOIN sys.columns
		ON tables.object_id = columns.object_id
		INNER JOIN sys.schemas
		ON schemas.schema_id = tables.schema_id
		WHERE columns.name LIKE ''' + @searchString + ''';
		-- Schemas
		INSERT INTO #object_data
			(database_name, schemaname, table_name, objectname, object_type)
		SELECT
			db_name() AS database_name,
			schemas.name AS schema_name,
			NULL AS table_name,
			schemas.name AS objectname,
			''Schema'' AS object_type
		FROM sys.schemas
		WHERE schemas.name LIKE ''' + @searchString + ''';

		-- Procedural TSQL
		INSERT INTO #object_data
			(database_name, schemaname, table_name, objectname, object_type)
		SELECT
			db_name() AS database_name,
			parent_schema.name AS schema_name,
			parent_object.name AS table_name,
			child_object.name AS objectname,
			CASE child_object.type 
				WHEN ''P'' THEN ''Stored Procedure''
				WHEN ''RF'' THEN ''Replication Filter Procedure''
				WHEN ''V'' THEN ''View''
				WHEN ''TR'' THEN ''DML Trigger''
				WHEN ''FN'' THEN ''Scalar Function''
				WHEN ''IF'' THEN ''Inline Table Valued Function''
				WHEN ''TF'' THEN ''SQL Table Valued Function''
				WHEN ''R'' THEN ''Rule''
			END	AS object_type
		FROM sys.sql_modules
		INNER JOIN sys.objects child_object
		ON sql_modules.object_id = child_object.object_id
		LEFT JOIN sys.objects parent_object
		ON parent_object.object_id = child_object.parent_object_id
		LEFT JOIN sys.schemas parent_schema
		ON parent_object.schema_id = parent_schema.schema_id
		WHERE child_object.name LIKE ''' + @searchString + '''
		OR sql_modules.definition LIKE ''' + @searchString + ''';

		-- Index Columns
		WITH CTE_INDEX_COLUMNS AS (
			SELECT -- User indexes (with column name matching search string)
				db_name() AS database_name,
				SCHEMA_DATA.name AS schemaname,
				TABLE_DATA.name AS table_name,
				INDEX_DATA.name AS index_name,
				STUFF(( SELECT  '', '' + SC.name
						FROM sys.tables AS ST
						INNER JOIN sys.indexes SI
						ON ST.object_id = SI.object_id
						INNER JOIN sys.index_columns IC
						ON SI.object_id = IC.object_id
						AND SI.index_id = IC.index_id
						INNER JOIN sys.all_columns SC
						ON ST.object_id = SC.object_id
						AND IC.column_id = SC.column_id
						WHERE INDEX_DATA.object_id = SI.object_id
						AND INDEX_DATA.index_id = SI.index_id
						AND IC.is_included_column = 0
						ORDER BY IC.key_ordinal
					FOR XML PATH('''')), 1, 2, '''') AS key_column_list,
					STUFF(( SELECT  '', '' + SC.name
						FROM sys.tables AS ST
						INNER JOIN sys.indexes SI
						ON ST.object_id = SI.object_id
						INNER JOIN sys.index_columns IC
						ON SI.object_id = IC.object_id
						AND SI.index_id = IC.index_id
						INNER JOIN sys.all_columns SC
						ON ST.object_id = SC.object_id
						AND IC.column_id = SC.column_id
						WHERE INDEX_DATA.object_id = SI.object_id
						AND INDEX_DATA.index_id = SI.index_id
						AND IC.is_included_column = 1
						ORDER BY IC.key_ordinal
					FOR XML PATH('''')), 1, 2, '''') AS include_column_list,
					''Index Column'' AS object_type
			FROM sys.indexes INDEX_DATA
			INNER JOIN sys.tables TABLE_DATA
			ON TABLE_DATA.object_id = INDEX_DATA.object_id
			INNER JOIN sys.schemas SCHEMA_DATA
			ON SCHEMA_DATA.schema_id = TABLE_DATA.schema_id
			WHERE TABLE_DATA.is_ms_shipped = 0
			AND INDEX_DATA.type_desc IN (''CLUSTERED'', ''NONCLUSTERED''))
		INSERT INTO #index_data
			(database_name, schemaname, table_name, index_name, key_column_list, include_column_list)
		SELECT
			database_name, schemaname, table_name, index_name, key_column_list, ISNULL(include_column_list, '''') AS include_column_list
		FROM CTE_INDEX_COLUMNS
		WHERE CTE_INDEX_COLUMNS.key_column_list LIKE ''' + @searchString + '''
		OR CTE_INDEX_COLUMNS.include_column_list LIKE ''' + @searchString + '''
		OR CTE_INDEX_COLUMNS.index_name LIKE ''' + @searchString + ''';'
		EXEC sp_executesql @sql;

		FETCH NEXT FROM DBCURSOR INTO @database_name;
	END
	
	SELECT
		*
	FROM #object_data;

	SELECT
		*
	FROM #index_data

	-- Search to see if text exists in any job steps
	SELECT
		j.job_id,
		s.srvname,
		j.name,
		js.step_id,
		js.command,
		j.enabled
	FROM msdb.dbo.sysjobs j
	INNER JOIN msdb.dbo.sysjobsteps js
	ON js.job_id = j.job_id
	INNER JOIN master.dbo.sysservers s
	ON s.srvid = j.originating_server_id
	WHERE js.command LIKE @searchString;

	DROP TABLE #object_data;
	DROP TABLE #index_data;
END
GO

EXEC dbo.search_all_schema N'BusinessEntityContact';
GO

EXEC dbo.search_all_schema N'PK_Sales';
GO

EXEC dbo.search_all_schema N'Production.Product';
GO

-- Listing 4-7.  Script to retrieve a list of server logins and roles.
SELECT
	server_principals.name AS Login_Name,
	server_principals.type_desc AS Account_Type
FROM sys.server_principals 
WHERE server_principals.name NOT LIKE '%##%'
ORDER BY server_principals.name, server_principals.type_desc;
GO

-- Listing 4-8.  Script that lists any user-created securables.
SELECT
    OBJECT_NAME(database_permissions.major_id) AS object_name,
	USER_NAME(database_permissions.grantee_principal_id) AS role_name,
	database_permissions.permission_name
FROM sys.database_permissions
WHERE database_permissions.class = 1
AND OBJECTPROPERTY(database_permissions.major_id, 'IsMSSHipped') = 0
ORDER BY OBJECT_NAME(database_permissions.major_id);
GO

-- Listing 4-9: TSQL to return relationships between server logins and database users.
CREATE TABLE #login_user_mapping (
    login_name NVARCHAR(MAX),
    database_name NVARCHAR(MAX),
    user_name NVARCHAR(MAX), 
    alias_name NVARCHAR(MAX));

INSERT INTO #login_user_mapping 
EXEC master.dbo.sp_msloginmappings;

SELECT
	* 
FROM #login_user_mapping 
ORDER BY database_name,
 	   user_name;

DROP TABLE #login_user_mapping;
GO

-- Listing 4-10.  Dynamic SQL to check database integrity on all databases on this instance.
DECLARE @databases TABLE
	(database_name NVARCHAR(MAX));

INSERT INTO @databases
	(database_name)
SELECT
	databases.name
FROM sys.databases;

DECLARE @sql_command NVARCHAR(MAX) = '';

SELECT @sql_command = @sql_command + '
DBCC CHECKDB (' + database_name + ');'
FROM @databases;

PRINT @sql_command;
EXEC sp_executesql @sql_command;
GO

-- Listing 4-11.  Dynamic SQL to gather row counts of all tables on this SQL Server instance.
SET NOCOUNT ON;

DECLARE @databases TABLE
	(database_name NVARCHAR(MAX));

CREATE TABLE #tables
	(database_name NVARCHAR(MAX),
	 schema_name NVARCHAR(MAX),
	 table_name NVARCHAR(MAX),
	 row_count BIGINT);

DECLARE @sql_command NVARCHAR(MAX) = '';

INSERT INTO @databases
	(database_name)
SELECT
	databases.name
FROM sys.databases
WHERE databases.name <> 'tempdb';

DECLARE @current_database NVARCHAR(MAX);
WHILE EXISTS (SELECT * FROM @databases)
BEGIN
	SELECT TOP 1 @current_database = database_name FROM @databases;
	
	SELECT @sql_command = @sql_command + '
		USE [' + @current_database + ']
		INSERT INTO #tables
			(database_name, schema_name, table_name, row_count)
		SELECT
			''' + @current_database + ''',
			schemas.name,
			tables.name,
			0
		FROM sys.tables
		INNER JOIN sys.schemas
		ON tables.schema_id = schemas.schema_id';
	EXEC sp_executesql @sql_command;
	DELETE FROM @databases WHERE database_name = @current_database;
END

SELECT @sql_command = '';
SELECT @sql_command = @sql_command + '
	UPDATE #tables
		SET row_count = (SELECT COUNT(*)
	FROM [' + database_name + '].[' + schema_name + '].[' + table_name + '])
	WHERE database_name = ''' + database_name + '''
	AND schema_name = ''' + schema_name + '''
	AND table_name = ''' + table_name + ''';'
FROM #tables;

SELECT (LEN(@sql_command) * 16) AS length_of_large_sql_command
EXEC sp_executesql @sql_command;

SELECT
	*
FROM #tables;

DROP TABLE #tables;
GO

-- SET NOCOUNT ON;

DECLARE @databases TABLE
	(database_name NVARCHAR(MAX));

CREATE TABLE #tables
	(database_name NVARCHAR(MAX),
	 schema_name NVARCHAR(MAX),
	 table_name NVARCHAR(MAX),
	 row_count BIGINT);

DECLARE @sql_command NVARCHAR(MAX) = '';

INSERT INTO @databases
	(database_name)
SELECT
	databases.name
FROM sys.databases
WHERE databases.name <> 'tempdb';

DECLARE @current_database NVARCHAR(MAX);
WHILE EXISTS (SELECT * FROM @databases)
BEGIN
	SELECT TOP 1 @current_database = database_name FROM @databases;

	SELECT @sql_command = '';

	SELECT @sql_command = @sql_command + '
		USE [' + @current_database + ']
		INSERT INTO #tables
			(database_name, schema_name, table_name, row_count)
		SELECT
			''' + @current_database + ''',
			schemas.name,
			tables.name,
			0
		FROM sys.tables
		INNER JOIN sys.schemas
		ON tables.schema_id = schemas.schema_id';
	EXEC sp_executesql @sql_command;

	SELECT @sql_command = '';
	SELECT @sql_command = @sql_command + '
		UPDATE #tables
			SET row_count = (SELECT COUNT(*)
		FROM [' + database_name + '].[' + schema_name + '].[' + table_name + '])
		WHERE database_name = ''' + database_name + '''
		AND schema_name = ''' + schema_name + '''
		AND table_name = ''' + table_name + ''';'
	FROM #tables
	WHERE database_name = @current_database;

	SELECT (LEN(@sql_command) * 16) + 2 AS length_of_large_sql_command
	EXEC sp_executesql @sql_command;

	DELETE FROM @databases WHERE database_name = @current_database;
END

SELECT
	*
FROM #tables;

DROP TABLE #tables;
GO

/*
-- ROW LEVEL SECURITY
-- https://docs.microsoft.com/en-us/sql/relational-databases/security/row-level-security?view=sql-server-2017
*/

CREATE TABLE dbo.employee_login
(	employee_id INT NOT NULL IDENTITY(1,1) CONSTRAINT PK_employee PRIMARY KEY CLUSTERED,
	first_name VARCHAR(100) NOT NULL,
	last_name VARCHAR(100) NOT NULL,
	username VARCHAR(50) NOT NULL,
	login_owner_username VARCHAR(50) NOT NULL);
GO

INSERT INTO dbo.employee_login
	(first_name, last_name, username, login_owner_username)
VALUES
	('Ed', 'Pollack', 'Ed', 'Ed'),
	('Ed', 'Pollack', 'epollack', 'Ed'),
	('Ed', 'Pollack', 'edwardjr', 'Ed'),
	('Theresa', 'Pollack', 'Theresa', 'Theresa'),
	('Nolan', 'Pollack', 'Nolan', 'Ed'),
	('Donna', '', 'Donna', 'Donna'),
	('Joe', '', 'Joe', 'Joe'),
	('Giganotosaurus', '', 'GFunk', 'Troodon'),
	('Tyrannosaurus', '', 'Trex', 'Troodon'),
	('Pteranodon', '', 'Pteranodon', 'Troodon'),
	('Troodon', '', 'Troodon', 'Ed');
GO

CREATE LOGIN [Ed] WITH PASSWORD = 'test_password', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;
CREATE USER [Ed] FROM LOGIN [Ed];
ALTER ROLE db_datareader ADD MEMBER [Ed];
GO

CREATE LOGIN [Troodon] WITH PASSWORD = 'test_password', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;
CREATE USER [Troodon] FROM LOGIN [Troodon];
ALTER ROLE db_datareader ADD MEMBER [Troodon];
GO

CREATE LOGIN [Nolan] WITH PASSWORD = 'test_password', CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF;
CREATE USER [Nolan] FROM LOGIN [Nolan];
ALTER ROLE db_datareader ADD MEMBER [Nolan];
GO

CREATE FUNCTION dbo.fn_employee_login_security_function (@user_name AS VARCHAR(50))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT
		1 AS fn_security_predicate_result
	FROM dbo.employee_login
	WHERE @user_name = SUSER_NAME();
GO

CREATE SECURITY POLICY employee_login_security_policy
ADD FILTER PREDICATE dbo.fn_employee_login_security_function(login_owner_username)
ON dbo.employee_login
WITH (STATE = ON);
GO

-- Returns 0 Rows
SELECT
	*
FROM dbo.employee_login;

EXECUTE AS LOGIN = 'Ed';
-- Returns 5 rows
SELECT
	*
FROM dbo.employee_login;

SELECT
	COUNT(*)
FROM dbo.employee_login;

REVERT

EXECUTE AS LOGIN = 'Nolan';
-- Returns 5 rows
SELECT
	*
FROM dbo.employee_login;

SELECT
	COUNT(*)
FROM dbo.employee_login;

REVERT

EXECUTE AS LOGIN = 'Troodon';
-- Returns 5 rows
SELECT
	*
FROM dbo.employee_login;

SELECT
	COUNT(*)
FROM dbo.employee_login;

REVERT

DROP SECURITY POLICY employee_login_security_policy;
GO

DROP FUNCTION dbo.fn_employee_login_security_function;
GO

CREATE SECURITY POLICY PersonSecurityPolicy
ADD FILTER PREDICATE [rls].[fn_securitypredicate]([CustomerId])
ON [dbo].[Customer]
ADD FILTER PREDICATE [rls].[fn_securitypredicate]([CustomerId])
ON [dbo].[Customer]
WITH (STATE = ON);

DROP SECURITY POLICY PersonSecurityPolicy;
GO

CREATE SECURITY POLICY PersonSecurityPolicy
ADD FILTER PREDICATE [rls].[fn_securitypredicate]([CustomerId])
ON [dbo].[Customer]
ADD BLOCK PREDICATE rls.tenantAccessPredicate(TenantId) ON dbo.Sales AFTER INSERT;  
WITH (STATE = ON);

SELECT
	*
FROM sys.security_policies;

SELECT
	*
FROM sys.security_predicates;

DROP SECURITY POLICY PersonSecurityPolicy;
GO
