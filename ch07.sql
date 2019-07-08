USE AdventureWorks2016CTP3;
SET STATISTICS IO ON;
SET NOCOUNT ON;
GO

-- Listing 7-1: Example of a cursor-based approach to building a comma-delimited list of IDs.
DECLARE @nextid INT;
DECLARE @myIDs NVARCHAR(MAX) = '';

DECLARE idcursor CURSOR FOR
SELECT TOP 100
	BusinessEntityID
FROM Person.Person
ORDER BY LastName;
OPEN idcursor;
FETCH NEXT FROM idcursor INTO @nextid;

WHILE @@FETCH_STATUS = 0
BEGIN
	SET @myIDs = @myIDs + CAST(@nextid AS NVARCHAR) + ',';
	FETCH NEXT FROM idcursor INTO @nextid;
END
SET @myIDs = LEFT(@myIDs, LEN(@myIDs) - 1);
CLOSE idcursor;
DEALLOCATE idcursor;

SELECT @myIDs AS comma_separated_output;
GO

-- Listing 7-2: Generating a list of IDs using XML.
DECLARE @myIDs NVARCHAR(MAX) = '';

SET @myIDs = STUFF((SELECT TOP 100 ',' + CAST(BusinessEntityID AS NVARCHAR)
FROM Person.Person
ORDER BY LastName
FOR XML PATH(''), TYPE
).value('.', 'NVARCHAR(MAX)'), 1, 1, '');

SELECT @myIDs;
GO

SELECT TOP 100 ',' + CAST(BusinessEntityID AS NVARCHAR) AS ID_CSV
FROM Person.Person
ORDER BY LastName;

SELECT (SELECT TOP 100 ',' + CAST(BusinessEntityID AS NVARCHAR)
FROM Person.Person
ORDER BY LastName
FOR XML PATH(''));

SELECT (SELECT TOP 100 ',' + CAST(BusinessEntityID AS NVARCHAR)
FROM Person.Person
ORDER BY LastName
FOR XML PATH(''), TYPE
).value('.', 'NVARCHAR(MAX)');

DECLARE @myIDs NVARCHAR(MAX) = '';

SET @myIDs = (SELECT TOP 100 ',' + CAST(BusinessEntityID AS NVARCHAR)
FROM Person.Person
ORDER BY LastName
FOR XML PATH(''), TYPE
).value('.', 'NVARCHAR(MAX)');

SELECT RIGHT(@myIDs, LEN(@myIDs) - 1);
SELECT SUBSTRING(@myIDs, 2, LEN(@myIDs) - 1);
GO

-- Listing 7-3: Generating a list of IDs by building a string directly into a variable.
DECLARE @myIDs NVARCHAR(MAX) = '';

SELECT TOP 100 @myIDs = @myIDs + CAST(BusinessEntityID AS NVARCHAR) + ','
FROM Person.Person
ORDER BY LastName;

SET @myIDs = LEFT(@myIDs, LEN(@myIDs) - 1);

SELECT @myIDs;
GO

-- Listing 7-4: Building a list with multiple columns and string literals.
DECLARE @myData NVARCHAR(MAX) = '';
SELECT @myData = 
	@myData + 'ContactTypeID: ' + CAST(ContactTypeID AS NVARCHAR) + ',Name: ' + Name + ','
FROM person.ContactType
SET @myData = LEFT(@myData, LEN(@myData) - 1);

SELECT @myData;
GO

-- Listing 7-5: Using ISNULL to eliminate the leading comma within the SELECT statement.
DECLARE @myData NVARCHAR(MAX);

SELECT @myData = 
	ISNULL(@myData + ',','') + 'ContactTypeID: ' + CAST(ContactTypeID AS NVARCHAR) + ',Name: ' + Name
FROM person.ContactType;

SELECT @myData;
GO

DECLARE @myData NVARCHAR(MAX);

SELECT @myData = 
	COALESCE(@myData + ',','') + 'ContactTypeID: ' + CAST(ContactTypeID AS NVARCHAR) + ',Name: ' + Name
FROM person.ContactType;

SELECT @myData;
GO

-- Listing 7-6: A reminder of SQL injection when building a list with dynamic SQL.
CREATE PROCEDURE dbo.return_person_data
	@last_name NVARCHAR(MAX) = NULL, @first_name NVARCHAR(MAX) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @return_data NVARCHAR(MAX) = '';
	DECLARE @sql_command NVARCHAR(MAX);
	DECLARE @parameter_list NVARCHAR(MAX);

	SELECT @parameter_list = '@output_data NVARCHAR(MAX) OUTPUT';

	SELECT @sql_command = '
	SELECT
		@output_data = @output_data + ''ID: '' + CAST(BusinessEntityID AS NVARCHAR) + '', Name: '' + FirstName + '' '' + LastName + '',''
	FROM Person.Person
	WHERE 1 = 1'
	IF @last_name IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND LastName LIKE ''%' + @last_name + '%''';
	IF @first_name IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND FirstName LIKE ''%' + @first_name + '%''';

	PRINT @sql_command;
	EXEC sp_executesql @sql_command, @parameter_list, @return_data OUTPUT;

	SELECT @return_data = LEFT(@return_data, LEN(@return_data) - 1);

	SELECT @return_data;
END
GO

EXEC dbo.return_person_data @first_name = 'Edward';
GO

EXEC dbo.return_person_data @first_name = '';
GO

EXEC dbo.return_person_data @first_name = 'whatever''; SELECT * FROM Person.Password; SELECT ''';
GO

-- Listing 7-7: Dynamic SQL list generation using parameters for inputs.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'return_person_data')
BEGIN
	DROP PROCEDURE dbo.return_person_data;
END
GO

CREATE PROCEDURE dbo.return_person_data
	@last_name NVARCHAR(MAX) = NULL, @first_name NVARCHAR(MAX) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SELECT @last_name = '%' + @last_name + '%';
	SELECT @first_name = '%' + @first_name + '%';

	DECLARE @return_data NVARCHAR(MAX) = '';
	DECLARE @sql_command NVARCHAR(MAX);
	DECLARE @parameter_list NVARCHAR(MAX);

	SELECT @parameter_list = '@output_data NVARCHAR(MAX) OUTPUT, @first_name NVARCHAR(MAX), @last_name NVARCHAR(MAX)';

	SELECT @sql_command = '
	SELECT
		@output_data = @output_data + ''ID: '' + CAST(BusinessEntityID AS NVARCHAR) + '', Name: '' + FirstName + '' '' + LastName + '',''
	FROM Person.Person
	WHERE 1 = 1'
	IF @last_name IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND LastName LIKE @last_name';
	IF @first_name IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND FirstName LIKE @first_name';

	PRINT @sql_command;
	EXEC sp_executesql @sql_command, @parameter_list, @return_data OUTPUT, @first_name, @last_name;

	SELECT @return_data = LEFT(@return_data, LEN(@return_data) - 1);

	SELECT @return_data;
END
GO

EXEC dbo.return_person_data @first_name = 'Edward';
GO

EXEC dbo.return_person_data @first_name = '';
GO

EXEC dbo.return_person_data @first_name = 'Edward''; SELECT * FROM Person.Password; SELECT ''';
GO

-- Listing 7-8: List generation stored procedure, with fixes for long waits and error messages.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'return_person_data')
BEGIN
	DROP PROCEDURE dbo.return_person_data;
END
GO

CREATE PROCEDURE dbo.return_person_data
	@last_name NVARCHAR(MAX) = NULL, @first_name NVARCHAR(MAX) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SELECT @last_name = '%' + @last_name + '%';
	SELECT @first_name = '%' + @first_name + '%';

	DECLARE @return_data NVARCHAR(MAX) = '';
	DECLARE @sql_command NVARCHAR(MAX);
	DECLARE @parameter_list NVARCHAR(MAX);

	SELECT @parameter_list = '@output_data NVARCHAR(MAX) OUTPUT, @first_name NVARCHAR(MAX), @last_name NVARCHAR(MAX)';

	SELECT @sql_command = '
	SELECT TOP 25
		@output_data = @output_data + ''ID: '' + CAST(BusinessEntityID AS NVARCHAR) + '', Name: '' + FirstName + '' '' + LastName + '',''
	FROM Person.Person
	WHERE 1 = 1'
	IF @last_name IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND LastName LIKE @last_name';
	IF @first_name IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND FirstName LIKE @first_name';

	PRINT @sql_command;
	EXEC sp_executesql @sql_command, @parameter_list, @return_data OUTPUT, @first_name, @last_name;

	IF LEN(@return_data) > 0 AND @return_data IS NOT NULL
		SELECT @return_data = LEFT(@return_data, LEN(@return_data) - 1);

	SELECT @return_data;
END
GO

EXEC dbo.return_person_data @first_name = 'Edward';
GO

EXEC dbo.return_person_data @first_name = '';
GO

EXEC dbo.return_person_data @first_name = 'Edward''; SELECT * FROM Person.Password; SELECT ''';
GO

-- Listing 7-9: Building a list using STRING_AGG
DECLARE @myData NVARCHAR(MAX);

SELECT @myData = 
	ISNULL(@myData + ',','') + SalesOrderHeader.SalesOrderNumber
FROM Sales.SalesOrderHeader
WHERE SalesOrderHeader.OrderDate = '5/31/2011';

SELECT @myData;
GO

-- Listing 7-10: Generating a list of order numbers using the STRING_AGG function.
SELECT
	STRING_AGG(SalesOrderHeader.SalesOrderNumber, ',')
FROM Sales.SalesOrderHeader
WHERE SalesOrderHeader.OrderDate = '5/31/2011';
GO

-- Listing 7-11: Generating multiple lists for given order dates.
SELECT
	SalesOrderHeader.OrderDate, STRING_AGG(SalesOrderHeader.SalesOrderNumber, ',') WITHIN GROUP (ORDER BY SalesOrderHeader.SalesOrderID ASC) AS OrderList
FROM Sales.SalesOrderHeader
WHERE SalesOrderHeader.OrderDate BETWEEN '5/31/2011' AND '6/30/2011'
GROUP BY SalesOrderHeader.OrderDate;
GO

-- Listing 7-12: Adding the order count and aggregate ordering into the order list result set.
SELECT
	SalesOrderHeader.OrderDate, STRING_AGG(SalesOrderHeader.SalesOrderNumber, ',') AS OrderList, COUNT(*) AS OrderCount
FROM Sales.SalesOrderHeader
WHERE SalesOrderHeader.OrderDate BETWEEN '5/31/2011' AND '6/30/2011'
GROUP BY SalesOrderHeader.OrderDate
ORDER BY COUNT(*) DESC;
GO