SET NOCOUNT ON;
GO

-- Very basic SELECT statement:
SELECT TOP 10 * FROM Person.Person;
GO

-- Rewriting the simple statement above using dynamic SQL:
DECLARE @sql_command NVARCHAR(MAX);
SELECT @sql_command = 'SELECT TOP 10 * FROM Person.Person';
EXEC (@sql_command);
GO

-- Example of the error received when omitting parenthesis from an EXEC statement:
DECLARE @sql_command NVARCHAR(MAX);
SELECT @sql_command = 'SELECT TOP 10 * FROM Person.Person';
EXEC @sql_command;
GO

DECLARE @sql_command NVARCHAR(MAX);
DECLARE @table_name NVARCHAR(100);
SELECT @table_name = 'Person.Person';
SELECT @sql_command = 'SELECT TOP 10 * FROM ' + @table_name;
EXEC (@sql_command);
GO

-- Listing 1-1
BACKUP DATABASE AdventureWorks2014
TO DISK='E:\SQLBackups\AdventureWorks2014.bak'
WITH COMPRESSION;
GO

-- Listing 1-2
DECLARE @database_list TABLE
	(database_name SYSNAME);

INSERT INTO @database_list
	(database_name)
SELECT
	name
FROM sys.databases
WHERE name LIKE 'AdventureWorks%';

DECLARE @sql_command NVARCHAR(MAX);
DECLARE @database_name SYSNAME;

DECLARE database_cursor CURSOR LOCAL FAST_FORWARD FOR
SELECT database_name FROM @database_list
OPEN database_cursor
FETCH NEXT FROM database_cursor INTO @database_name;

WHILE @@FETCH_STATUS = 0
BEGIN
	SELECT @sql_command = '
	BACKUP DATABASE ' + @database_name + '
	TO DISK=''E:\SQLBackups\' + @database_name + '.bak''
	WITH COMPRESSION;'
	
	EXEC (@sql_command);

	FETCH NEXT FROM database_cursor INTO @database_name;
END

CLOSE database_cursor;
DEALLOCATE database_cursor;
GO

-- Listing 1-4
-- This will temporarily store the list of databases that we will back up below.
DECLARE @database_list TABLE
	(database_name SYSNAME);

INSERT INTO @database_list
	(database_name)
SELECT
	name
FROM sys.databases
WHERE name LIKE 'AdventureWorks%';
-- This WHERE clause may be adjusted to backup other databases besides those starting with "AdventureWorks"

DECLARE @sql_command NVARCHAR(MAX);
DECLARE @database_name SYSNAME;
DECLARE @date_string VARCHAR(17) = CONVERT(VARCHAR, CURRENT_TIMESTAMP, 112) + '_' + REPLACE(RIGHT(CONVERT(NVARCHAR, CURRENT_TIMESTAMP, 120), 8), ':', '');

-- Use a cursor to iterate through databases, one by one.
DECLARE database_cursor CURSOR FOR
SELECT database_name FROM @database_list
OPEN database_cursor
FETCH NEXT FROM database_cursor INTO @database_name;

WHILE @@FETCH_STATUS = 0 -- Continue looping until the cursor has reached the end of the database list.
BEGIN
	-- Customize the backup file name to use the database name, as well as the date and time
	SELECT @sql_command = '
	BACKUP DATABASE ' + @database_name + '
	TO DISK=''E:\SQLBackups\' + @database_name + '_' + @date_string + '.bak'' WITH COMPRESSION;'
	
	EXEC (@sql_command);

	FETCH NEXT FROM database_cursor INTO @database_name;
END

-- Clean up our cursor object.
CLOSE database_cursor;
DEALLOCATE database_cursor;
GO

DECLARE @CMD NVARCHAR(MAX);
SELECT @CMD = 'SELLECT TOP 17 * FROM Person.Person';
-- SELLECT TOP 17 * FROM Person.Person
EXEC (@CMD);
GO

-- Listing 1-5
DECLARE @debug BIT = 1;

DECLARE @database_list TABLE
	(database_name SYSNAME);

INSERT INTO @database_list
	(database_name)
SELECT
	name
FROM sys.databases
WHERE name LIKE 'AdventureWorks%';
-- This WHERE clause may be adjusted to backup other databases besides those starting with "AdventureWorks"

DECLARE @sql_command NVARCHAR(MAX);
DECLARE @database_name SYSNAME;
DECLARE @date_string VARCHAR(17) = CONVERT(VARCHAR, CURRENT_TIMESTAMP, 112) + '_' + REPLACE(RIGHT(CONVERT(NVARCHAR, CURRENT_TIMESTAMP, 120), 8), ':', '');

-- Use a cursor to iterate through databases, one by one.
DECLARE database_cursor CURSOR FOR
SELECT database_name FROM @database_list
OPEN database_cursor
FETCH NEXT FROM database_cursor INTO @database_name;

WHILE @@FETCH_STATUS = 0 -- Continue looping until the cursor has reacdhed the end of the database list.
BEGIN
	-- Customize the backup file name to use the database name, as well as the date and time
	SELECT @sql_command = '
	BACKUP DATABASE ' + @database_name + '
	TO DISK=''E:\SQLBackups\' + @database_name + '_' + @date_string + '.bak''
	WITH COMPRESSION;'
	
	IF @debug = 1
		PRINT @sql_command
	ELSE
		EXEC (@sql_command);

	FETCH NEXT FROM database_cursor INTO @database_name;
END
-- Clean up our cursor object.
CLOSE database_cursor;
DEALLOCATE database_cursor;
GO

-- Listing 1-6
DECLARE @CMD NVARCHAR(MAX) = ''; -- This will hold the final SQL to execute
DECLARE @first_name NVARCHAR(50) = 'Edward'; -- First name as entered in search box
SET @CMD = 'SELECT PERSON.FirstName,PERSON.LastName,PHONE.PhoneNumber,PTYPE.Name FROM Person.Person PERSON INNER JOIN Person.PersonPhone PHONE ON PERSON.BusinessEntityID = PHONE.BusinessEntityID INNER JOIN Person.PhoneNumberType PTYPE ON PHONE.PhoneNumberTypeID = PTYPE.PhoneNumberTypeID WHERE PERSON.FirstName = ''' + @first_name + '''';
PRINT @CMD;
EXEC (@CMD);
GO

sp_executesql N'SELECT COUNT(*) FROM Person.Person';
GO

DECLARE @sql_command NVARCHAR(MAX) = 'SELECT COUNT(*) FROM Person.Person';
EXEC sp_executesql @sql_command;
GO

-- Listing 1-9
DECLARE @schema VARCHAR(25) = NULL;
DECLARE @table VARCHAR(25) = 'Person';
DECLARE @sql_command VARCHAR(MAX);
SELECT @sql_command = 'SELECT COUNT(*) ' + 'FROM ' +  @schema + '.' + @table;
PRINT @sql_command;
SELECT @sql_command = 'SELECT COUNT(*) ' + 'FROM ' +  ISNULL(@schema, 'Person') + '.' + @table;
PRINT @sql_command;
SELECT @sql_command = 'SELECT COUNT(*) ' + 'FROM ' + CASE WHEN @schema IS NULL THEN 'Person' ELSE @schema END + '.' + @table;
PRINT @sql_command;
GO

SELECT CONCAT('SELECT COUNT(*) ', 'FROM ', 'Person.', 'Person');

DECLARE @schema NVARCHAR(25) = 'Person';
DECLARE @table NVARCHAR(25)= 'Person';
DECLARE @sql_command NVARCHAR(MAX);
SELECT @sql_command = CONCAT ('SELECT COUNT(*) ', 'FROM ', @schema, '.', @table);
PRINT @sql_command
GO

DECLARE @string NVARCHAR(MAX) = '   This is a string with extra whitespaces     ';
SELECT @string;
SELECT LTRIM(@string);
SELECT RTRIM(@string);
SELECT TRIM(@string); -- Available in SQL Server 2017 and later
GO

DECLARE @string NVARCHAR(MAX) = 'The stegosaurus is my favorite dinosaur';
SELECT CHARINDEX('dinosaur', @string);
GO

DECLARE @string NVARCHAR(MAX) = 'The stegosaurus is my favorite dinosaur';
SELECT STUFF(@string, 5, 0, 'purple ');
SELECT STUFF(@string, 5, 11, 't-rex');
SELECT STUFF(@string, 32, 8, 'animal!');
GO

DECLARE @string NVARCHAR(MAX) = CAST(CURRENT_TIMESTAMP AS NVARCHAR);
SELECT REPLACE(@string, ' ', '');
SELECT REPLACE(REPLACE(@string, ' ', ''), ':', '');
SELECT REPLACE(REPLACE(REPLACE(REPLACE(@string, ' ', ''), ':', ''), 'AM', ''), 'PM', '');
GO

DECLARE @string NVARCHAR(MAX) = 'Text;with&extraneous(characters)';
SELECT TRANSLATE(@string, ';&()', '    ');
GO

DECLARE @string NVARCHAR(MAX) = CAST(CURRENT_TIMESTAMP AS NVARCHAR);
SELECT SUBSTRING(@string, 1, 3);
GO

SELECT 'Look, a robot' + REPLICATE('!', 50)
GO

DECLARE @serial_number NVARCHAR(MAX) = '91542278';
SELECT REPLICATE(0, 20 - LEN(@serial_number)) + @serial_number;
GO

DECLARE @string NVARCHAR(MAX) = '123456789';
SELECT REVERSE(@string);
GO
