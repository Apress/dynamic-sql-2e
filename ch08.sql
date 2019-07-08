USE AdventureWorks2016CTP3;
SET STATISTICS IO ON;
SET NOCOUNT ON;
GO

-- Listing 8-1: Stored procedure to read optimization and execution data from the query plan cache.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'read_query_plan_cache')
BEGIN
	DROP PROCEDURE dbo.read_query_plan_cache;
END
GO

CREATE PROCEDURE dbo.read_query_plan_cache
	@text_string NVARCHAR(MAX) = NULL
AS
BEGIN
	SELECT @text_string = '%' + @text_string + '%';
	DECLARE @sql_command NVARCHAR(MAX);
	DECLARE @parameter_list NVARCHAR(MAX) = '@text_string NVARCHAR(MAX)';

	IF @text_string IS NULL
		SELECT @sql_command = '
			SELECT TOP 25
				DB_NAME(execution_plan.dbid) AS database_name,
				cached_plans.objtype AS ObjectType,
				OBJECT_NAME(sql_text.objectid, sql_text.dbid) AS ObjectName,
				query_stats.creation_time,
				query_stats.last_execution_time,
				query_stats.last_worker_time AS cpu_last_execution,
				query_stats.last_logical_reads AS reads_last_execution,
				query_stats.last_elapsed_time AS duration_last_execution,
				query_stats.last_rows AS rows_last_execution,
				cached_plans.size_in_bytes,
				cached_plans.usecounts AS ExecutionCount,
				sql_text.TEXT AS QueryText,
				execution_plan.query_plan,
				cached_plans.plan_handle
			FROM sys.dm_exec_cached_plans cached_plans
			INNER JOIN sys.dm_exec_query_stats query_stats
			ON cached_plans.plan_handle = query_stats.plan_handle
			CROSS APPLY sys.dm_exec_sql_text(cached_plans.plan_handle) AS sql_text
			CROSS APPLY sys.dm_exec_query_plan(cached_plans.plan_handle) AS execution_plan';
	ELSE
		SELECT @sql_command = '
			SELECT TOP 25
				DB_NAME(execution_plan.dbid) AS database_name,
				cached_plans.objtype AS ObjectType,
				OBJECT_NAME(sql_text.objectid, sql_text.dbid) AS ObjectName,
				query_stats.creation_time,
				query_stats.last_execution_time,
				query_stats.last_worker_time AS cpu_last_execution,
				query_stats.last_logical_reads AS reads_last_execution,
				query_stats.last_elapsed_time AS duration_last_execution,
				query_stats.last_rows AS rows_last_execution,
				cached_plans.size_in_bytes,
				cached_plans.usecounts AS ExecutionCount,
				sql_text.TEXT AS QueryText,
				execution_plan.query_plan,
				cached_plans.plan_handle
			FROM sys.dm_exec_cached_plans cached_plans
			INNER JOIN sys.dm_exec_query_stats query_stats
			ON cached_plans.plan_handle = query_stats.plan_handle
			CROSS APPLY sys.dm_exec_sql_text(cached_plans.plan_handle) AS sql_text
			CROSS APPLY sys.dm_exec_query_plan(cached_plans.plan_handle) AS execution_plan
		WHERE sql_text.TEXT LIKE @text_string';

		EXEC sp_executesql @sql_command, @parameter_list, @text_string
END
GO

-- Listing 8-2: Example stored procedure to be used to test parameter sniffing.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'get_products_by_model')
BEGIN
	DROP PROCEDURE dbo.get_products_by_model;
END
GO

CREATE PROCEDURE dbo.get_products_by_model (@firstProductModelID INT, @lastProductModelID INT) 
AS
BEGIN
	SELECT
		PRODUCT.Name,
		PRODUCT.ProductID,
		PRODUCT.ProductModelID,
		PRODUCT.ProductNumber,
		MODEL.Name
	FROM Production.Product PRODUCT
	INNER JOIN Production.ProductModel MODEL
	ON MODEL.ProductModelID = PRODUCT.ProductModelID
	WHERE PRODUCT.ProductModelID BETWEEN @firstProductModelID AND @lastProductModelID;
END
GO

EXEC get_products_by_model 120, 125;
GO

EXEC dbo.read_query_plan_cache 'get_products_by_model';
GO

DBCC FREEPROCCACHE;
EXEC get_products_by_model 0, 10000;
GO

EXEC get_products_by_model 0, 10000;
EXEC get_products_by_model 0, 10000;
EXEC get_products_by_model 0, 10000;
EXEC get_products_by_model 0, 10000;
EXEC get_products_by_model 0, 10000;
GO

EXEC dbo.read_query_plan_cache 'get_products_by_model';
GO

DBCC FREEPROCCACHE;
EXEC get_products_by_model 120, 125;
EXEC get_products_by_model 0, 10000;
GO

EXEC dbo.read_query_plan_cache 'get_products_by_model';
GO

INSERT INTO Sales.SalesPerson
	(BusinessEntityID, TerritoryID, SalesQuota, Bonus, CommissionPct, SalesYTD, SalesLastYear, rowguid, ModifiedDate)
VALUES
	(1, 1, 1000000, 289, 0.17, 0, 0, NEWID(), CURRENT_TIMESTAMP);

UPDATE Sales.SalesOrderHeader
	SET SalesPersonID = 1
WHERE SalesPersonID IS NULL;

UPDATE STATISTICS Sales.SalesOrderHeader;
GO

-- Listing 8-3: Search procedure to be used for demonstrating parameter sniffing.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'get_sales_orders_by_sales_person')
BEGIN
	DROP PROCEDURE dbo.get_sales_orders_by_sales_person;
END
GO

CREATE PROCEDURE dbo.get_sales_orders_by_sales_person
	@SalesPersonID INT, @RowCount INT, @Offset INT
AS
BEGIN
	DECLARE @sql_command NVARCHAR(MAX);
	DECLARE @parameter_list NVARCHAR(MAX) = '@SalesPersonID INT, @RowCount INT, @Offset INT';
	-- Add one to the offset to get the correct starting row
	SELECT @Offset = @Offset + 1;

	SELECT @sql_command = '
	WITH CTE_PRODUCTS AS (
		SELECT
			ROW_NUMBER() OVER (ORDER BY OrderDate ASC) AS rownum,
			SalesOrderHeader.SalesOrderID,
			SalesOrderHeader.Status,
			SalesOrderHeader.OrderDate,
			SalesOrderHeader.ShipDate,
			SalesOrderDetail.UnitPrice,
			SalesOrderDetail.LineTotal
		FROM Sales.SalesOrderHeader
		INNER JOIN Sales.SalesOrderDetail
		ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID
		WHERE SalesOrderHeader.SalesPersonID = @SalesPersonID
		)
	SELECT
		*
	FROM CTE_PRODUCTS
	WHERE rownum BETWEEN @Offset AND @Offset + @RowCount;';

	EXEC sp_executesql @sql_command, @parameter_list, @SalesPersonID, @RowCount, @Offset;
END
GO

DBCC FREEPROCCACHE;
EXEC dbo.get_sales_orders_by_sales_person 1, 1000, 0;
GO

EXEC dbo.read_query_plan_cache 'CTE_PRODUCTS';
GO

-- Listing 8-4: Resulting query text as executed in the dynamic search with paging.
(@SalesPersonID INT, @RowCount INT, @Offset INT)
	WITH CTE_PRODUCTS AS (
		SELECT
			ROW_NUMBER() OVER (ORDER BY OrderDate ASC) AS rownum,
			SalesOrderHeader.SalesOrderID,
			SalesOrderHeader.Status,
			SalesOrderHeader.OrderDate,
			SalesOrderHeader.ShipDate,
			SalesOrderDetail.UnitPrice,
			SalesOrderDetail.LineTotal
		FROM Sales.SalesOrderHeader
		INNER JOIN Sales.SalesOrderDetail
		ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID
		WHERE SalesOrderHeader.SalesPersonID = @SalesPersonID
		)
	SELECT
		*
	FROM CTE_PRODUCTS
	WHERE rownum BETWEEN @Offset AND @Offset + @RowCount;
GO

DBCC FREEPROCCACHE;
EXEC dbo.get_sales_orders_by_sales_person 285, 1000, 0;
GO

EXEC dbo.read_query_plan_cache 'CTE_PRODUCTS'; 
GO

DBCC FREEPROCCACHE;
EXEC dbo.get_sales_orders_by_sales_person 1, 1000, 0; 
GO

EXEC dbo.get_sales_orders_by_sales_person 285, 1000, 0;
GO

EXEC dbo.read_query_plan_cache 'CTE_PRODUCTS';
GO

-- Listing 8-5: Example usage of the RECOMPILE query hint.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'get_sales_orders_by_sales_person')
BEGIN
	DROP PROCEDURE dbo.get_sales_orders_by_sales_person;
END
GO

CREATE PROCEDURE dbo.get_sales_orders_by_sales_person
	@SalesPersonID INT, @RowCount INT, @Offset INT
AS
BEGIN
	DECLARE @sql_command NVARCHAR(MAX);
	DECLARE @parameter_list NVARCHAR(MAX) = '@SalesPersonID INT, @RowCount INT, @Offset INT';

	SELECT @sql_command = '
	WITH CTE_PRODUCTS AS (
		SELECT
			ROW_NUMBER() OVER (ORDER BY OrderDate ASC) AS rownum,
			SalesOrderHeader.SalesOrderID,
			SalesOrderHeader.Status,
			SalesOrderHeader.OrderDate,
			SalesOrderHeader.ShipDate,
			SalesOrderDetail.UnitPrice,
			SalesOrderDetail.LineTotal
		FROM Sales.SalesOrderHeader
		INNER JOIN Sales.SalesOrderDetail
		ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID
		WHERE SalesOrderHeader.SalesPersonID = @SalesPersonID
		)
	SELECT
		*
	FROM CTE_PRODUCTS
	WHERE rownum BETWEEN @Offset AND @Offset + @RowCount
	OPTION (RECOMPILE);';

	EXEC sp_executesql @sql_command, @parameter_list, @SalesPersonID, @RowCount, @Offset;
END
GO

DBCC FREEPROCCACHE;
EXEC dbo.get_sales_orders_by_sales_person 1, 1000, 0;

EXEC dbo.get_sales_orders_by_sales_person 285, 1000, 0;

EXEC dbo.read_query_plan_cache 'CTE_PRODUCTS';
GO

-- Listing 8-6: An AdventureWorks query guaranteed to perform poorly.	
SELECT DISTINCT
	PRODUCT.ProductID,
	PRODUCT.Name
FROM Production.Product PRODUCT
INNER JOIN Sales.SalesOrderDetail DETAIL
ON PRODUCT.ProductID = DETAIL.ProductID
OR PRODUCT.rowguid = DETAIL.rowguid
GO

-- Listing 8-7: The optimized version of the slow query from Listing 8-6.	
SELECT
	PRODUCT.ProductID,
	PRODUCT.Name
FROM Production.Product PRODUCT
INNER JOIN Sales.SalesOrderDetail DETAIL
ON PRODUCT.ProductID = DETAIL.ProductID
UNION
SELECT
	PRODUCT.ProductID,
	PRODUCT.Name
FROM Production.Product PRODUCT
INNER JOIN Sales.SalesOrderDetail DETAIL
ON PRODUCT.rowguid = DETAIL.rowguid
GO

CREATE NONCLUSTERED INDEX NCI_production_product_ProductModelID ON Production.Product (ProductModelID) INCLUDE (Name);
GO

-- Listing 8-8: Stored procedure that re-declares parameters as local variables.	
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'get_products_by_model_local')
BEGIN
	DROP PROCEDURE dbo.get_products_by_model_local;
END
GO

CREATE PROCEDURE dbo.get_products_by_model_local (@firstProductModelID INT, @lastProductModelID INT) 
AS
BEGIN
	DECLARE @ProductModelID1 INT = @firstProductModelID;
	DECLARE @ProductModelID2 INT = @lastProductModelID;

	SELECT
		PRODUCT.Name,
		PRODUCT.ProductID,
		PRODUCT.ProductModelID,
		PRODUCT.ProductNumber,
		MODEL.Name
	FROM Production.Product PRODUCT
	INNER JOIN Production.ProductModel MODEL
	ON MODEL.ProductModelID = PRODUCT.ProductModelID
	WHERE PRODUCT.ProductModelID BETWEEN @ProductModelID1 AND @ProductModelID2;
END
GO

DBCC FREEPROCCACHE;
EXEC dbo.get_products_by_model_local 120, 125;
EXEC dbo.get_products_by_model_local 0, 10000;
GO

DBCC FREEPROCCACHE;
EXEC dbo.get_products_by_model_local 120, 125;
EXEC dbo.get_products_by_model_local 0, 10000;
EXEC dbo.get_products_by_model_local 120, 125;
EXEC dbo.get_products_by_model_local 0, 10000;
GO

EXEC dbo.read_query_plan_cache 'get_products_by_model_local';
GO

DBCC FREEPROCCACHE;
EXEC dbo.get_products_by_model 0, 10000;
GO

DBCC FREEPROCCACHE;
EXEC dbo.get_products_by_model_local 0, 10000;
GO

-- Listing 8-9: Example of using the OPTIMIZE FOR query hint.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'get_products_by_model')
BEGIN
	DROP PROCEDURE dbo.get_products_by_model;
END
GO
CREATE PROCEDURE dbo.get_products_by_model (@firstProductModelID INT, @lastProductModelID INT) 
AS
BEGIN
	SELECT
		PRODUCT.Name,
		PRODUCT.ProductID,
		PRODUCT.ProductModelID,
		PRODUCT.ProductNumber,
		MODEL.Name
	FROM Production.Product PRODUCT
	INNER JOIN Production.ProductModel MODEL
	ON MODEL.ProductModelID = PRODUCT.ProductModelID
	WHERE PRODUCT.ProductModelID BETWEEN @firstProductModelID AND @lastProductModelID
	OPTION (OPTIMIZE FOR (@firstProductModelID = 0, @lastProductModelID = 10000));
END
GO

DBCC FREEPROCCACHE;
EXEC dbo.get_products_by_model 0, 10000;
GO

-- Listing 8-10: Example of using the OPTIMIZE FOR UNKNOWN query hint.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'get_products_by_model')
BEGIN
	DROP PROCEDURE dbo.get_products_by_model;
END
GO
CREATE PROCEDURE dbo.get_products_by_model (@firstProductModelID INT, @lastProductModelID INT) 
AS
BEGIN
	SELECT
		PRODUCT.Name,
		PRODUCT.ProductID,
		PRODUCT.ProductModelID,
		PRODUCT.ProductNumber,
		MODEL.Name
	FROM Production.Product PRODUCT
	INNER JOIN Production.ProductModel MODEL
	ON MODEL.ProductModelID = PRODUCT.ProductModelID
	WHERE PRODUCT.ProductModelID BETWEEN @firstProductModelID AND @lastProductModelID
	OPTION (OPTIMIZE FOR (@firstProductModelID UNKNOWN, @lastProductModelID UNKNOWN));
END
GO

DBCC FREEPROCCACHE;
EXEC dbo.get_products_by_model 0, 10000;
GO

-- Listing 8-11: Example of using dynamic SQL to attempt to control the optimization process of a stored procedure.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'get_products_by_model')
BEGIN
	DROP PROCEDURE dbo.get_products_by_model;
END
GO
CREATE PROCEDURE dbo.get_products_by_model (@firstProductModelID INT, @lastProductModelID INT) 
AS
BEGIN
	DECLARE @sql_command NVARCHAR(MAX);

	SELECT @sql_command = '
		SELECT
			PRODUCT.Name,
			PRODUCT.ProductID,
			PRODUCT.ProductModelID,
			PRODUCT.ProductNumber,
			MODEL.Name
		FROM Production.Product PRODUCT
		INNER JOIN Production.ProductModel MODEL
		ON MODEL.ProductModelID = PRODUCT.ProductModelID
		WHERE PRODUCT.ProductModelID BETWEEN ' + CAST(@firstProductModelID AS NVARCHAR(MAX)) + ' AND ' + CAST(@lastProductModelID AS NVARCHAR(MAX)) + ';';

	EXEC sp_executesql @sql_command;
END
GO

DBCC FREEPROCCACHE;
EXEC dbo.get_products_by_model 120, 125;
EXEC dbo.get_products_by_model 0, 10000;
EXEC dbo.get_products_by_model 120, 125;
EXEC dbo.get_products_by_model 0, 10000;
GO

EXEC dbo.read_query_plan_cache 'get_products_by_model';
GO

-- Listing 8-12: Script that cleans up any objects created in this chapter.
IF EXISTS (SELECT * FROM sys.indexes WHERE indexes.name = 'NCI_production_product_ProductModelID')
BEGIN
	DROP INDEX NCI_production_product_ProductModelID ON Production.Product;
END
GO
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'get_products_by_model_local')
BEGIN
	DROP PROCEDURE dbo.get_products_by_model;
END
GO
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'get_sales_orders_by_sales_person')
BEGIN
	DROP PROCEDURE dbo.get_sales_orders_by_sales_person;
END
GO
