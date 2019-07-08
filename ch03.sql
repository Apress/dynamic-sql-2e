USE AdventureWorks2016CTP3;
SET NOCOUNT ON;
GO

-- Listing 3-1.  Search stored procedure, with six optional parameters (no dynamic SQL).
CREATE PROCEDURE dbo.search_products
@product_name NVARCHAR(50) = NULL, @product_number NVARCHAR(25) = NULL, @product_model NVARCHAR(50) = NULL,	@product_subcategory NVARCHAR(50) = NULL, @product_sizemeasurecode NVARCHAR(50) = NULL, @product_weightunitmeasurecode NVARCHAR(50) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	SET @product_name = '%' + @product_name + '%';
	SET @product_number = '%' + @product_number + '%';
	SET @product_model = '%' + @product_model + '%';

	SELECT
		Product.Name AS product_name,
		Product.ProductNumber AS product_number,
		ProductModel.Name AS product_model_name,
		ProductSubcategory.Name AS product_subcategory_name,
		SizeUnitMeasureCode.Name AS size_unit_measure_code,
		WeightUnitMeasureCode.Name AS weight_unit_measure_code
	FROM Production.Product
	LEFT JOIN Production.ProductModel
	ON Product.ProductModelID = ProductModel.ProductModelID
	LEFT JOIN Production.ProductSubcategory
	ON Product.ProductSubcategoryID = ProductSubcategory.ProductSubcategoryID
	LEFT JOIN Production.UnitMeasure SizeUnitMeasureCode
	ON Product.SizeUnitMeasureCode = SizeUnitMeasureCode.UnitMeasureCode
	LEFT JOIN Production.UnitMeasure WeightUnitMeasureCode
	ON Product.WeightUnitMeasureCode = WeightUnitMeasureCode.UnitMeasureCode
	WHERE (Product.Name LIKE @product_name OR @product_name IS NULL)
	AND (Product.ProductNumber LIKE @product_number OR @product_number IS NULL)
	AND (ProductModel.Name LIKE @product_model OR @product_model IS NULL)
	AND (ProductSubcategory.Name = @product_subcategory OR @product_subcategory IS NULL)
	AND (SizeUnitMeasureCode.Name = @product_sizemeasurecode OR @product_sizemeasurecode IS NULL)
	AND (WeightUnitMeasureCode.Name = @product_weightunitmeasurecode OR @product_weightunitmeasurecode IS NULL);
END
GO

EXEC dbo.search_products @product_number = 'BK-M18', @product_model = 'Mountain', @product_subcategory = 'Mountain Bikes';
EXEC dbo.search_products @product_name = 'Mountain-500 Black, 48';
EXEC dbo.search_products;
GO

-- Listing 3-2.  Search stored procedure, with six optional parameters (using dynamic SQL).
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'search_products')
BEGIN
	DROP PROCEDURE dbo.search_products;
END
GO

CREATE PROCEDURE dbo.search_products
	@product_name NVARCHAR(50) = NULL, @product_number NVARCHAR(25) = NULL, @product_model NVARCHAR(50) = NULL,
	@product_subcategory NVARCHAR(50) = NULL, @product_sizemeasurecode NVARCHAR(50) = NULL,
	@product_weightunitmeasurecode NVARCHAR(50) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	SET @product_name = '%' + @product_name + '%';
	SET @product_number = '%' + @product_number + '%';
	SET @product_model = '%' + @product_model + '%';

	DECLARE @sql_command NVARCHAR(MAX);
	DECLARE @parameter_list NVARCHAR(MAX) = '@product_name NVARCHAR(50), @product_number NVARCHAR(25),
	@product_model NVARCHAR(50), @product_subcategory NVARCHAR(50), @product_sizemeasurecode NVARCHAR(50),
	@product_weightunitmeasurecode NVARCHAR(50)';

	SELECT @sql_command = '
	SELECT
		Product.Name AS product_name,
		Product.ProductNumber AS product_number,
		ProductModel.Name AS product_model_name,
		ProductSubcategory.Name AS product_subcategory_name,
		SizeUnitMeasureCode.Name AS size_unit_measure_code,
		WeightUnitMeasureCode.Name AS weight_unit_measure_code
	FROM Production.Product
	LEFT JOIN Production.ProductModel
	ON Product.ProductModelID = ProductModel.ProductModelID
	LEFT JOIN Production.ProductSubcategory
	ON Product.ProductSubcategoryID = ProductSubcategory.ProductSubcategoryID
	LEFT JOIN Production.UnitMeasure SizeUnitMeasureCode
	ON Product.SizeUnitMeasureCode = SizeUnitMeasureCode.UnitMeasureCode
	LEFT JOIN Production.UnitMeasure WeightUnitMeasureCode
	ON Product.WeightUnitMeasureCode = SizeUnitMeasureCode.UnitMeasureCode
	WHERE 1 = 1'
	IF @product_name IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND Product.Name LIKE @product_name'
	IF @product_number IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND Product.ProductNumber LIKE @product_number'
	IF @product_model IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND ProductModel.Name LIKE @product_model'
	IF @product_subcategory IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND ProductSubcategory.Name = @product_subcategory'
	IF @product_sizemeasurecode IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND SizeUnitMeasureCode.Name = @product_sizemeasurecode'
	IF @product_weightunitmeasurecode IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND WeightUnitMeasureCode.Name = @product_weightunitmeasurecode'

	PRINT @sql_command;
	EXEC sp_executesql @sql_command, @parameter_list, @product_name, @product_number,
	@product_model, @product_subcategory, @product_sizemeasurecode,	@product_weightunitmeasurecode
END
GO

EXEC dbo.search_products @product_number = 'BK-M18', @product_model = 'Mountain', @product_subcategory = 'Mountain Bikes';
GO

-- Listing 3-4.  Search grid stored procedure, using dynamic SQL.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'search_products')
BEGIN
	DROP PROCEDURE dbo.search_products;
END
GO

CREATE PROCEDURE dbo.search_products
	@product_name NVARCHAR(50) = NULL, @product_number NVARCHAR(25) = NULL, @product_model NVARCHAR(50) = NULL,
	@product_subcategory NVARCHAR(50) = NULL, @product_sizemeasurecode NVARCHAR(50) = NULL,
	@product_weightunitmeasurecode NVARCHAR(50) = NULL,
	@show_color BIT = 0, @show_safetystocklevel BIT = 0, @show_reorderpoint BIT = 0, @show_standard_cost BIT = 0,
	@show_catalog_description BIT = 0, @show_subcategory_modified_date BIT = 0, @show_product_model BIT = 0,
	@show_product_subcategory BIT = 0, @show_product_sizemeasurecode BIT = 0, @show_product_weightunitmeasurecode BIT = 0
AS
BEGIN
	SET NOCOUNT ON;
	-- Add "%" delimiters to parameters that will be searched as wildcards.
	SET @product_name = '%' + @product_name + '%';
	SET @product_number = '%' + @product_number + '%';
	SET @product_model = '%' + @product_model + '%';

	DECLARE @sql_command NVARCHAR(MAX);
	-- Define the parameter list for filter criteria
	DECLARE @parameter_list NVARCHAR(MAX) = '@product_name NVARCHAR(50), @product_number NVARCHAR(25),
	@product_model NVARCHAR(50), @product_subcategory NVARCHAR(50), @product_sizemeasurecode NVARCHAR(50),
	@product_weightunitmeasurecode NVARCHAR(50)';

	-- Generate the command string section for the SELECT columns
	SELECT @sql_command = '
	SELECT
		Product.Name AS product_name,
		Product.ProductNumber AS product_number,';
		IF @show_product_model = 1 SELECT @sql_command = @sql_command + '
			ProductModel.Name AS product_model_name,';
		IF @show_product_subcategory = 1 SELECT @sql_command = @sql_command + '
			ProductSubcategory.Name AS product_subcategory_name,';
		IF @show_product_sizemeasurecode = 1 SELECT @sql_command = @sql_command + '
			SizeUnitMeasureCode.Name AS size_unit_measure_code,';
		IF @show_product_weightunitmeasurecode = 1 SELECT @sql_command = @sql_command + '
			WeightUnitMeasureCode.Name AS weight_unit_measure_code,';
		IF @show_color = 1 SELECT @sql_command = @sql_command + '
			Product.Color AS product_color,';
		IF @show_safetystocklevel = 1 SELECT @sql_command = @sql_command + '
			Product.SafetyStockLevel AS product_safety_stock_level,';
		IF @show_reorderpoint = 1 SELECT @sql_command = @sql_command + '
			Product.ReorderPoint AS product_reorderpoint,';
		IF @show_standard_cost = 1 SELECT @sql_command = @sql_command + '
			Product.StandardCost AS product_standard_cost,';
		IF @show_catalog_description = 1 SELECT @sql_command = @sql_command + '
			ProductModel.CatalogDescription AS productmodel_catalog_description,';
		IF @show_subcategory_modified_date = 1 SELECT @sql_command = @sql_command + '
			ProductSubcategory.ModifiedDate AS product_subcategory_modified_date';
	-- In the event that there is a comma at the end of our command string, remove it before continuing:
	IF (SELECT SUBSTRING(@sql_command, LEN(@sql_command), 1)) = ','
		SELECT @sql_command = LEFT(@sql_command, LEN(@sql_command) - 1);
	SELECT @sql_command = @sql_command + '
	FROM Production.Product'
	-- Put together the JOINs based on what tables are required by the search.
	IF (@product_model IS NOT NULL OR @show_product_model = 1 OR @show_catalog_description = 1)
		SELECT @sql_command = @sql_command + '
	LEFT JOIN Production.ProductModel
	ON Product.ProductModelID = ProductModel.ProductModelID';
	IF (@product_subcategory IS NOT NULL OR @show_subcategory_modified_date = 1 OR @show_product_subcategory = 1)
		SELECT @sql_command = @sql_command + '
	LEFT JOIN Production.ProductSubcategory
	ON Product.ProductSubcategoryID = ProductSubcategory.ProductSubcategoryID';
	IF (@product_sizemeasurecode IS NOT NULL OR @show_product_sizemeasurecode = 1)
		SELECT @sql_command = @sql_command + '
	LEFT JOIN Production.UnitMeasure SizeUnitMeasureCode
	ON Product.SizeUnitMeasureCode = SizeUnitMeasureCode.UnitMeasureCode';
	IF (@product_weightunitmeasurecode IS NOT NULL OR @show_product_weightunitmeasurecode = 1)
		SELECT @sql_command = @sql_command + '
	LEFT JOIN Production.UnitMeasure WeightUnitMeasureCode
	ON Product.WeightUnitMeasureCode = SizeUnitMeasureCode.UnitMeasureCode'

	SELECT @sql_command = @sql_command + '
	WHERE 1 = 1'
	-- Build the WHERE clause based on which tables are referenced and required by the search.
	IF @product_name IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND Product.Name LIKE @product_name'
	IF @product_number IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND Product.ProductNumber LIKE @product_number'
	IF @product_model IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND ProductModel.Name LIKE @product_model'
	IF @product_subcategory IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND ProductSubcategory.Name = @product_subcategory'
	IF @product_sizemeasurecode IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND SizeUnitMeasureCode.Name = @product_sizemeasurecode'
	IF @product_weightunitmeasurecode IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND WeightUnitMeasureCode.Name = @product_weightunitmeasurecode'

	PRINT @sql_command;
	EXEC sp_executesql @sql_command, @parameter_list, @product_name, @product_number,
	@product_model, @product_subcategory, @product_sizemeasurecode,	@product_weightunitmeasurecode
END
GO

EXEC dbo.search_products @product_number = 'BK-M18', @product_model = 'Mountain', @product_subcategory = 'Mountain Bikes';
EXEC dbo.search_products @product_name = 'Mountain-500 Black, 48';
EXEC dbo.search_products;

EXEC dbo.search_products @product_model = 'Mountain', @show_product_model = 1, @show_color = 1
GO

-- Listing 3-6.  Search proc with a simplified SELECT statement, using fewer conditionals.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'search_products')
BEGIN
	DROP PROCEDURE dbo.search_products;
END
GO

-- Search with a check to avoid empty searches
CREATE PROCEDURE dbo.search_products
	@product_name NVARCHAR(50) = NULL, @product_number NVARCHAR(25) = NULL, @product_model NVARCHAR(50) = NULL,
	@product_subcategory NVARCHAR(50) = NULL, @product_sizemeasurecode NVARCHAR(50) = NULL,
	@product_weightunitmeasurecode NVARCHAR(50) = NULL,
	@show_color BIT = 0, @show_safetystocklevel BIT = 0, @show_reorderpoint BIT = 0, @show_standard_cost BIT = 0,
	@show_catalog_description BIT = 0, @show_subcategory_modified_date BIT = 0, @show_product_model BIT = 0,
	@show_product_subcategory BIT = 0, @show_product_sizemeasurecode BIT = 0, @show_product_weightunitmeasurecode BIT = 0
AS
BEGIN
	SET NOCOUNT ON;

	IF COALESCE(@product_name, @product_number, @product_model, @product_subcategory,
				@product_sizemeasurecode, @product_weightunitmeasurecode) IS NULL
		RETURN;

	-- Add "%" delimiters to parameters that will be searched as wildcards.
	SET @product_name = '%' + @product_name + '%';
	SET @product_number = '%' + @product_number + '%';
	SET @product_model = '%' + @product_model + '%';

	DECLARE @sql_command NVARCHAR(MAX);
	-- Define the parameter list for filter criteria
	DECLARE @parameter_list NVARCHAR(MAX) = '@product_name NVARCHAR(50), @product_number NVARCHAR(25),
	@product_model NVARCHAR(50), @product_subcategory NVARCHAR(50), @product_sizemeasurecode NVARCHAR(50),
	@product_weightunitmeasurecode NVARCHAR(50)';

-- Generate the simplified command string section for the SELECT columns
SELECT @sql_command = '
	SELECT
		Product.Name AS product_name,
		Product.ProductNumber AS product_number,';
		IF @show_product_model = 1 OR @show_catalog_description = 1 SELECT @sql_command = @sql_command + '
			ProductModel.Name AS product_model_name,
			ProductModel.CatalogDescription AS productmodel_catalog_description,';
		IF @show_product_subcategory = 1 OR @show_subcategory_modified_date = 1 SELECT @sql_command = @sql_command + '
			ProductSubcategory.Name AS product_subcategory_name,
			ProductSubcategory.ModifiedDate AS product_subcategory_modified_date,';
		IF @show_product_sizemeasurecode = 1 SELECT @sql_command = @sql_command + '
			SizeUnitMeasureCode.Name AS size_unit_measure_code,';
		IF @show_product_weightunitmeasurecode = 1 SELECT @sql_command = @sql_command + '
			WeightUnitMeasureCode.Name AS weight_unit_measure_code,';
		IF @show_color = 1 OR @show_safetystocklevel = 1 OR @show_reorderpoint = 1 OR @show_standard_cost = 1
		SELECT @sql_command = @sql_command + '
			Product.Color AS product_color,
			Product.SafetyStockLevel AS product_safety_stock_level,
			Product.ReorderPoint AS product_reorderpoint,
			Product.StandardCost AS product_standard_cost';
	-- In the event that there is a comma at the end of our command string, remove it before continuing:
	IF (SELECT SUBSTRING(@sql_command, LEN(@sql_command), 1)) = ','
		SELECT @sql_command = LEFT(@sql_command, LEN(@sql_command) - 1);
	SELECT @sql_command = @sql_command + '
	FROM Production.Product'
	-- Put together the JOINs based on what tables are required by the search.
	IF (@product_model IS NOT NULL OR @show_product_model = 1 OR @show_catalog_description = 1)
		SELECT @sql_command = @sql_command + '
	LEFT JOIN Production.ProductModel
	ON Product.ProductModelID = ProductModel.ProductModelID';
	IF (@product_subcategory IS NOT NULL OR @show_subcategory_modified_date = 1 OR @show_product_subcategory = 1)
		SELECT @sql_command = @sql_command + '
	LEFT JOIN Production.ProductSubcategory
	ON Product.ProductSubcategoryID = ProductSubcategory.ProductSubcategoryID';
	IF (@product_sizemeasurecode IS NOT NULL OR @show_product_sizemeasurecode = 1)
		SELECT @sql_command = @sql_command + '
	LEFT JOIN Production.UnitMeasure SizeUnitMeasureCode
	ON Product.SizeUnitMeasureCode = SizeUnitMeasureCode.UnitMeasureCode';
	IF (@product_weightunitmeasurecode IS NOT NULL OR @show_product_weightunitmeasurecode = 1)
		SELECT @sql_command = @sql_command + '
	LEFT JOIN Production.UnitMeasure WeightUnitMeasureCode
	ON Product.WeightUnitMeasureCode = SizeUnitMeasureCode.UnitMeasureCode'

	SELECT @sql_command = @sql_command + '
	WHERE 1 = 1'
	-- Build the WHERE clause based on which tables are referenced and required by the search.
	IF @product_name IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND Product.Name LIKE @product_name'
	IF @product_number IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND Product.ProductNumber LIKE @product_number'
	IF @product_model IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND ProductModel.Name LIKE @product_model'
	IF @product_subcategory IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND ProductSubcategory.Name = @product_subcategory'
	IF @product_sizemeasurecode IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND SizeUnitMeasureCode.Name = @product_sizemeasurecode'
	IF @product_weightunitmeasurecode IS NOT NULL
		SELECT @sql_command = @sql_command + '
		AND WeightUnitMeasureCode.Name = @product_weightunitmeasurecode'

	PRINT @sql_command;
	EXEC sp_executesql @sql_command, @parameter_list, @product_name, @product_number,
	@product_model, @product_subcategory, @product_sizemeasurecode,	@product_weightunitmeasurecode
END
GO

EXEC dbo.search_products @show_product_model = 1;
EXEC dbo.search_products;
GO

SELECT	Name,
		ProductNumber,
		Color,
		Size,
		DaysToManufacture
FROM Production.Product
WHERE Product.Color IS NULL
AND ProductID BETWEEN 316 AND 359
GO

WITH CTE_PRODUCTS AS (
	SELECT
		ROW_NUMBER() OVER (ORDER BY ProductID ASC) AS rownum,
		Name,
		ProductNumber,
		Color,
		Size,
		DaysToManufacture
	FROM Production.Product
	WHERE Product.Color IS NULL)
SELECT
	Name,
	ProductNumber,
	Color,
	Size,
	DaysToManufacture
FROM CTE_PRODUCTS
WHERE rownum BETWEEN 5 AND 29
GO

-- Listing 3-7.  Sales order detail search, with a variety of input parameters.
CREATE PROCEDURE dbo.search_sales_order_detail
@tracking_number NVARCHAR(25), @offset_by_this_many_rows INT = 0, @row_count_to_return INT = 25, @return_all_results BIT = 0
AS
BEGIN
	SET NOCOUNT ON;
	-- Add wildcard delimiters to the tracking number
	SELECT @tracking_number = '%' + @tracking_number + '%';

	-- If the result set is small, return all results to the application for display.
	IF @return_all_results = 1
	BEGIN
		SELECT
			SalesOrderHeader.OrderDate,
			SalesOrderHeader.ShipDate,
			SalesOrderHeader.Status,
			SalesOrderHeader.PurchaseOrderNumber,
			SalesOrderDetail.CarrierTrackingNumber,
			SalesOrderDetail.OrderQty,
			SalesOrderDetail.UnitPrice,
			SalesOrderDetail.UnitPriceDiscount,
			SalesOrderDetail.LineTotal,
			Product.Name,
			Product.ProductNumber
		FROM Sales.SalesOrderHeader
		INNER JOIN Sales.SalesOrderDetail
		ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID
		INNER JOIN Production.Product
		ON SalesOrderDetail.ProductID = Product.ProductID
		WHERE CarrierTrackingNumber LIKE @tracking_number
		ORDER BY SalesOrderDetail.SalesOrderDetailID;
	END
	ELSE
	BEGIN
		SELECT
			SalesOrderHeader.OrderDate,
			SalesOrderHeader.ShipDate,
			SalesOrderHeader.Status,
			SalesOrderHeader.PurchaseOrderNumber,
			SalesOrderDetail.CarrierTrackingNumber,
			SalesOrderDetail.OrderQty,
			SalesOrderDetail.UnitPrice,
			SalesOrderDetail.UnitPriceDiscount,
			SalesOrderDetail.LineTotal,
			Product.Name,
			Product.ProductNumber
		FROM Sales.SalesOrderHeader
		INNER JOIN Sales.SalesOrderDetail
		ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID
		INNER JOIN Production.Product
		ON SalesOrderDetail.ProductID = Product.ProductID
		WHERE CarrierTrackingNumber LIKE @tracking_number
		ORDER BY SalesOrderDetail.SalesOrderDetailID
		OFFSET @offset_by_this_many_rows ROWS
		FETCH NEXT @row_count_to_return ROWS ONLY;
	END
END
GO

EXEC dbo.search_sales_order_detail '4911-403C-98', NULL, NULL, 1;
EXEC dbo.search_sales_order_detail '491';
EXEC dbo.search_sales_order_detail '491', 25, 50, 0;
GO

-- Listing 3-8.  Sales order detail search that detects input type based on string form.
IF EXISTS (SELECT * FROM sys.procedures WHERE procedures.name = 'search_sales_order_detail')
BEGIN
	DROP PROCEDURE dbo.search_sales_order_detail;
END
GO

CREATE PROCEDURE dbo.search_sales_order_detail
	@input_search_data NVARCHAR(25), @offset_by_this_many_rows INT = 0, @row_count_to_return INT = 25, @return_all_results BIT = 0
AS
BEGIN
	SET NOCOUNT ON;
	-- For this search procedure, do not allow blank input.  If blank is entered, return immediately with no result set.
	-- Input parameter does not allow NULLs
	IF LTRIM(RTRIM(@input_search_data)) = ''
		RETURN;

	-- Pad the input string with spaces, in case it isn't 25 characters long.  This will avoid string truncation below.
	SET @input_search_data = @input_search_data + REPLICATE(' ', 25 - LEN(@input_search_data));

	-- Parse the @input_search_data to determine the data it references
	DECLARE @input_type NVARCHAR(25);

	-- Search by Sales Order Number: Starts with "SO" and at least 5 numbers
	IF (LEFT(@input_search_data, 2) = 'SO' AND ISNUMERIC(SUBSTRING(@input_search_data, 3, 5)) = 1)
		SET @input_type = 'SalesOrderNumber';
	ELSE
	-- Search by Purchase Order Number: Starts with "PO" and at least 10 numbers
	IF (LEFT(@input_search_data, 2) = 'PO' AND ISNUMERIC(SUBSTRING(@input_search_data, 3, 10)) = 1)
		SET @input_type = 'PurchaseOrderNumber';
	ELSE
	-- Search by Account Number: Starts with two number, a hyphen, 4 numbers, a hyphen, and at least 6 additional numbers
	IF (ISNUMERIC(LEFT(@input_search_data, 2)) = 1 AND SUBSTRING(@input_search_data, 3, 1) = '-' AND ISNUMERIC(SUBSTRING(@input_search_data, 4, 4)) = 1
		AND SUBSTRING(@input_search_data, 8, 1) = '-' AND ISNUMERIC(SUBSTRING(@input_search_data, 9, 6)) = 1)
		SET @input_type = 'AccountNumber';
	ELSE
	-- Search by Carrier Tracking Number: 4 Alphanumeric, 1 hyphen, 4 alphanumeric, one hyphen, and two alphanumeric
	IF (PATINDEX('%[^a-zA-Z0-9]%' , LEFT(@input_search_data, 4)) = 0 AND SUBSTRING(@input_search_data, 5, 1) = '-' AND PATINDEX('%[^a-zA-Z0-9]%' , SUBSTRING(@input_search_data, 6, 4)) = 0
		AND SUBSTRING(@input_search_data, 10, 1) = '-' AND PATINDEX('%[^a-zA-Z0-9]%' , SUBSTRING(@input_search_data, 11, 2)) = 0)
		SET @input_type = 'CarrierTrackingNumber';
	ELSE
		-- Search by Product Number: Starts with two letters, a dash, and four alphanumeric characters: AA-12YZ
	IF (PATINDEX('%[^a-zA-Z]%' , LEFT(@input_search_data, 2)) = 0 AND SUBSTRING(@input_search_data, 3, 1) = '-' AND PATINDEX('%[^a-zA-Z0-9]%' , SUBSTRING(@input_search_data, 4, 4)) = 0)
		SET @input_type = 'ProductNumber';
	ELSE
	-- Default our input to carrier tracking number, if no other format is identified.
		SET @input_type = 'CarrierTrackingNumber';

	-- Remove additional padding to prevent bad string matches.
	-- Add a wildcard delimiter to the end of the input, to account for additional characters at the end.
	SELECT @input_search_data = LTRIM(RTRIM(@input_search_data)) + '%';

	DECLARE @sql_command NVARCHAR(MAX);
	DECLARE @parameter_list NVARCHAR(MAX);

	-- Create the parameter list and initial command string
	SET @parameter_list = '@input_search_data NVARCHAR(25), @offset_by_this_many_rows INT, @row_count_to_return INT';
	SET @sql_command = '
		SELECT
			SalesOrderHeader.OrderDate,
			SalesOrderHeader.ShipDate,
			SalesOrderHeader.Status,
			SalesOrderHeader.PurchaseOrderNumber,
			SalesOrderHeader.AccountNumber,
			SalesOrderHeader.SalesOrderNumber,
			SalesOrderDetail.CarrierTrackingNumber,
			SalesOrderDetail.OrderQty,
			SalesOrderDetail.UnitPrice,
			SalesOrderDetail.UnitPriceDiscount,
			SalesOrderDetail.LineTotal,
			Product.Name,
			Product.ProductNumber
		FROM Sales.SalesOrderHeader
		INNER JOIN Sales.SalesOrderDetail
		ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID
		INNER JOIN Production.Product
		ON SalesOrderDetail.ProductID = Product.ProductID';

	-- Based on the value of @input_type, dynamically generate the WHERE clause.
	IF @input_type = 'ProductNumber'
		SET @sql_command = @sql_command + '
		WHERE Product.ProductNumber LIKE @input_search_data';
	ELSE IF @input_type = 'SalesOrderNumber'
		SET @sql_command = @sql_command + '
		WHERE SalesOrderHeader.SalesOrderNumber LIKE @input_search_data';
	ELSE IF @input_type = 'PurchaseOrderNumber'
		SET @sql_command = @sql_command + '
		WHERE SalesOrderHeader.PurchaseOrderNumber LIKE @input_search_data';
	ELSE IF @input_type = 'AccountNumber'
		SET @sql_command = @sql_command + '
		WHERE SalesOrderHeader.AccountNumber LIKE @input_search_data';
	ELSE IF @input_type = 'CarrierTrackingNumber'
		SET @sql_command = @sql_command + '
		WHERE SalesOrderDetail.CarrierTrackingNumber LIKE @input_search_data';

	SET @sql_command = @sql_command + '
		ORDER BY SalesOrderDetail.SalesOrderDetailID';

	-- If there are any row limitations, append them here
	SET @sql_command = @sql_command + '
		OFFSET @offset_by_this_many_rows ROWS';
	IF @return_all_results = 0
		SET @sql_command = @sql_command + '
		FETCH NEXT @row_count_to_return ROWS ONLY;';

	PRINT @sql_command;
	EXEC sp_executesql @sql_command, @parameter_list, @input_search_data, @offset_by_this_many_rows, @row_count_to_return;
END
GO

EXEC dbo.search_sales_order_detail @input_search_data = 'BK-M82B-42';
EXEC dbo.search_sales_order_detail @input_search_data = 'PO125', @offset_by_this_many_rows = 0, @row_count_to_return = 50, @return_all_results = 0;
EXEC dbo.search_sales_order_detail @input_search_data = 'SO43662', @return_all_results = 1;
GO

-- Listing 3-9.  Retrieving a count of rows for a specific result set.
SELECT
COUNT(*)
FROM Sales.SalesOrderHeader
INNER JOIN Sales.SalesOrderDetail
ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID
INNER JOIN Production.Product
ON SalesOrderDetail.ProductID = Product.ProductID
WHERE SalesOrderHeader.PurchaseOrderNumber LIKE 'PO125%';
GO

-- Listing 3-10.  Retrieving current and total row counts alongside the result set.
SELECT
	COUNT(SalesOrderDetailID) OVER (ORDER BY SalesOrderDetailID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS row_count_current,
	COUNT(SalesOrderDetailID) OVER (ORDER BY SalesOrderDetailID ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS row_count_total,
	SalesOrderHeader.OrderDate,
	SalesOrderHeader.ShipDate,
	SalesOrderHeader.Status,
	SalesOrderHeader.PurchaseOrderNumber,
	SalesOrderHeader.AccountNumber,
	SalesOrderHeader.SalesOrderNumber,
	SalesOrderDetail.CarrierTrackingNumber,
	SalesOrderDetail.OrderQty,
	SalesOrderDetail.UnitPrice,
	SalesOrderDetail.UnitPriceDiscount,
	SalesOrderDetail.LineTotal,
	Product.Name,
	Product.ProductNumber
FROM Sales.SalesOrderHeader
INNER JOIN Sales.SalesOrderDetail
ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID
INNER JOIN Production.Product
ON SalesOrderDetail.ProductID = Product.ProductID
WHERE SalesOrderHeader.PurchaseOrderNumber LIKE 'PO125%'
ORDER BY SalesOrderDetail.SalesOrderDetailID;
GO

-- Listing 3-11.  Retrieving current and total row counts alongside the result set with data paging.
WITH CTE_SEARCH_DATA AS (
	SELECT
		COUNT(SalesOrderDetailID) OVER (ORDER BY SalesOrderDetailID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS row_count_current,
		COUNT(SalesOrderDetailID) OVER (ORDER BY SalesOrderDetailID ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS row_count_total,
		SalesOrderHeader.OrderDate,
		SalesOrderHeader.ShipDate,
		SalesOrderHeader.Status,
		SalesOrderHeader.PurchaseOrderNumber,
		SalesOrderHeader.AccountNumber,
		SalesOrderHeader.SalesOrderNumber,
		SalesOrderDetail.CarrierTrackingNumber,
		SalesOrderDetail.OrderQty,
		SalesOrderDetail.UnitPrice,
		SalesOrderDetail.UnitPriceDiscount,
		SalesOrderDetail.LineTotal,
		Product.Name,
		Product.ProductNumber
	FROM Sales.SalesOrderHeader
	INNER JOIN Sales.SalesOrderDetail
	ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID
	INNER JOIN Production.Product
	ON SalesOrderDetail.ProductID = Product.ProductID
	WHERE SalesOrderHeader.PurchaseOrderNumber LIKE 'PO125%')
SELECT
	*
FROM CTE_SEARCH_DATA
ORDER BY CTE_SEARCH_DATA.row_count_current
OFFSET 25 ROWS
FETCH NEXT 50 ROWS ONLY;
GO

-- Listing 3-12.  Dynamic SQL is used to make row counts into optional components of the result set.
DECLARE @include_row_counts BIT = 0;
DECLARE @sql_command NVARCHAR(MAX);

SELECT @sql_command = '
WITH CTE_SEARCH_DATA AS (
	SELECT';
IF @include_row_counts = 1
	SELECT @sql_command = @sql_command + '
		COUNT(SalesOrderDetailID) OVER (ORDER BY SalesOrderDetailID ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS row_count_current,
		COUNT(SalesOrderDetailID) OVER (ORDER BY SalesOrderDetailID ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS row_count_total,';
SELECT @sql_command = @sql_command + '
		SalesOrderHeader.OrderDate,
		SalesOrderHeader.ShipDate,
		SalesOrderHeader.Status,
		SalesOrderHeader.PurchaseOrderNumber,
		SalesOrderHeader.AccountNumber,
		SalesOrderHeader.SalesOrderNumber,
		SalesOrderDetail.CarrierTrackingNumber,
		SalesOrderDetail.OrderQty,
		SalesOrderDetail.UnitPrice,
		SalesOrderDetail.UnitPriceDiscount,
		SalesOrderDetail.LineTotal,
		Product.Name,
		Product.ProductNumber
	FROM Sales.SalesOrderHeader
	INNER JOIN Sales.SalesOrderDetail
	ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID
	INNER JOIN Production.Product
	ON SalesOrderDetail.ProductID = Product.ProductID
	WHERE SalesOrderHeader.PurchaseOrderNumber LIKE ''PO125%'')
SELECT
	*
FROM CTE_SEARCH_DATA';
IF @include_row_counts = 1
	SELECT @sql_command = @sql_command + '
ORDER BY CTE_SEARCH_DATA.row_count_current';
ELSE
SELECT @sql_command = @sql_command + '
ORDER BY CTE_SEARCH_DATA.OrderDate';
SELECT @sql_command = @sql_command + '
OFFSET 25 ROWS
FETCH NEXT 50 ROWS ONLY;';

PRINT @sql_command;
EXEC sp_executesql @sql_command;
GO

-- Listing 3-13: The command string generated in listing 3-12, which omits row counts.
WITH CTE_SEARCH_DATA AS (
	SELECT
		SalesOrderHeader.OrderDate,
		SalesOrderHeader.ShipDate,
		SalesOrderHeader.Status,
		SalesOrderHeader.PurchaseOrderNumber,
		SalesOrderHeader.AccountNumber,
		SalesOrderHeader.SalesOrderNumber,
		SalesOrderDetail.CarrierTrackingNumber,
		SalesOrderDetail.OrderQty,
		SalesOrderDetail.UnitPrice,
		SalesOrderDetail.UnitPriceDiscount,
		SalesOrderDetail.LineTotal,
		Product.Name,
		Product.ProductNumber
	FROM Sales.SalesOrderHeader
	INNER JOIN Sales.SalesOrderDetail
	ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID
	INNER JOIN Production.Product
	ON SalesOrderDetail.ProductID = Product.ProductID
	WHERE SalesOrderHeader.PurchaseOrderNumber LIKE 'PO125%')
SELECT
	*
FROM CTE_SEARCH_DATA
ORDER BY CTE_SEARCH_DATA.OrderDate
OFFSET 25 ROWS
FETCH NEXT 50 ROWS ONLY;
GO

-- Listing 3-14.  Sums/counts returned based on input parameters, using dynamic SQL. 
DECLARE @start_date DATE = '2014-06-01';
DECLARE @end_date DATE = '2014-06-30';
DECLARE @include_order_count BIT = 1;
DECLARE @include_order_total BIT = 1;
IF @include_order_count = 0 AND @include_order_total = 0
	RETURN;
DECLARE @parameter_list NVARCHAR(MAX);
DECLARE @sql_command NVARCHAR(MAX);

SELECT @parameter_list = '@start_date DATE, @end_date DATE'

SELECT @sql_command = '
	SELECT';
IF @include_order_count = 1
SELECT @sql_command = @sql_command + '
	COUNT(DISTINCT SalesOrderDetail.SalesOrderDetailID) AS sales_order_count,';
IF @include_order_total = 1
SELECT @sql_command = @sql_command + '
	SUM(SalesOrderDetail.LineTotal) AS total_revenue,';
SELECT @sql_command = @sql_command + '
	1 AS place_holder
	FROM Sales.SalesOrderHeader
	INNER JOIN Sales.SalesOrderDetail
	ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID
	WHERE OrderDate BETWEEN @start_date AND @end_date';

PRINT @sql_command;
EXEC sp_executesql @sql_command, @parameter_list, @start_date, @end_date;	
GO



