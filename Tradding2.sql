USE TraddingDB;
GO

INSERT INTO brands (name) VALUES ('Brand A'), ('Brand B');

INSERT INTO categories (name) VALUES ('Beverages'), ('Snacks');

INSERT INTO measurement_header (um_name) VALUES ('Liter'), ('Kilogram');

INSERT INTO measurement_details (unit_name, equvilant, um_id)
VALUES 
('ml', 1000, 5),
('g', 1000, 10);

INSERT INTO items (name, barcode, category_id, brand_id, amount, purchase_price, profit_rate, warning_percentage)
VALUES 
('Orange ', '100011', 1, 1, 100, 20.00, 0.25, 10.00),
('Potato ', '100012', 2, 2, 200, 10.00, 0.40, 5.00),
('Orange Juice', '100001', 1, 1, 100, 2.00, 0.25, 10.00),
('Potato Chips', '100002', 2, 2, 200, 1.00, 0.40, 5.00);

INSERT INTO warehousese (name, phone, address)
VALUES 
('Main Warehouse', '123456789', '123 Main St'),
('Backup Warehouse', '987654321', '456 Backup Ave');

INSERT INTO suppliers (name, phone, address)
VALUES 
('Fresh Supplier Co.', '111222333', 'Market Street'),
('Snack Express', '444555666', 'Snack Ave');

INSERT INTO customers (name, phone, email, address)
VALUES 
('John Doe', '1234567890', 'john@example.com', '123 Main St'),
('Jane Smith', '9876543210', 'jane@example.com', '456 Oak Rd');

---=========================Insert Purvhasing Invoice With Details - PROCEDURE ===============================
CREATE TYPE ItemTableType AS TABLE (
    item_barcode VARCHAR(100),
    warehouse_id INT,
    unit_id INT,
    amount INT,
    price DECIMAL(10,2)
);

ALTER PROCEDURE usp_InsertInvoiceWithDetails
    @invoice_id UNIQUEIDENTIFIER,
    @supplier_id INT,
    @sale DECIMAL(10, 4),
    @vat DECIMAL(10, 4),
    @quantity_amount INT,
    @items ItemTableType READONLY
AS
BEGIN
    SET NOCOUNT ON;

    IF @quantity_amount = 0
    BEGIN
        RAISERROR('Quantity amount cannot be zero.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @adjustment DECIMAL(10, 4) = (@vat - @sale) / @quantity_amount;

        INSERT INTO invoice_header (invoice_num, supplier_id, sale_percentage, vat, quantaty_amount)
        VALUES (@invoice_id, @supplier_id, @sale, @vat, @quantity_amount);

        -- Insert details
        INSERT INTO invoice_details (
            invoice_num, item_barcode, warehouse_id, unit_id, amount, price )
        SELECT
            @invoice_id,
            item_barcode,
            warehouse_id,
            unit_id,
            amount,
            price + @adjustment
        FROM @items;

        -- Update total price
        UPDATE ih
        SET ih.total_price = (
            SELECT SUM(price * amount)
            FROM invoice_details
            WHERE invoice_num = ih.invoice_num
        )
        FROM invoice_header ih
        WHERE ih.invoice_num = @invoice_id;

        COMMIT TRANSACTION;
    END TRY

	BEGIN CATCH
		ROLLBACK TRANSACTION;
    
		PRINT 'Error occurred:';
		PRINT ERROR_MESSAGE();
	END CATCH

END;

DECLARE @myItems AS ItemTableType;
INSERT INTO @myItems (item_barcode, warehouse_id, unit_id, amount, price)
VALUES 
    ('100011', 102, 10, 2, 100),
    ('100012', 101, 15, 3, 150);

DECLARE @id uniqueidentifier = NEWID();
EXEC usp_InsertInvoiceWithDetails
    @id,        -- invoice_id
    201,            -- supplier_id
    5.00,           -- sale
    10.00,          -- vat
    5,              -- quantity_amount
    @myItems;       -- items (TVP)

SELECT * FROM items
SELECT * FROM warehouse_items

SELECT * FROM invoice_header
SELECT * FROM invoice_details

CREATE TYPE SellingItemTableType AS TABLE (
    item_barcode VARCHAR(100),
    warehouse_id INT,
    unit_id INT,
    amount INT,
    price DECIMAL(10,2)
);

---=========================Insert Selling Invoice With Details - PROCEDURE ===============================
CREATE PROCEDURE usp_InsertSellingInvoiceWithDetails
    @invoice_id UNIQUEIDENTIFIER,
    @customer_id INT,
    @sale DECIMAL(10, 4),
    @vat DECIMAL(10, 4),
    @quantity_amount INT,
    @items SellingItemTableType READONLY
AS
BEGIN
    SET NOCOUNT ON;

    IF @quantity_amount = 0
    BEGIN
        RAISERROR('Quantity amount cannot be zero.', 16, 1);
        RETURN;
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @adjustment DECIMAL(10, 4) = (@vat - @sale) / @quantity_amount;

        INSERT INTO selling_invoice_header (invoice_num, customer_id, sale_percentage, vat, quantaty_amount)
        VALUES (@invoice_id, @customer_id, @sale, @vat, @quantity_amount);

        -- Insert invoice details
        INSERT INTO selling_invoice_details (
            invoice_num, item_barcode, warehouse_id, unit_id, amount, price)
        SELECT
            @invoice_id,
            item_barcode,
            warehouse_id,
            unit_id,
            amount,
            price + @adjustment
        FROM @items;

        -- Update total price in header
        UPDATE ih
        SET ih.total_price = (
            SELECT SUM(price * amount)
            FROM selling_invoice_details
            WHERE invoice_num = ih.invoice_num
        )
        FROM selling_invoice_header ih
        WHERE ih.invoice_num = @invoice_id;

        COMMIT TRANSACTION;
    END TRY

    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error occurred:';
        PRINT ERROR_MESSAGE();
    END CATCH
END;

DECLARE @sellItems AS SellingItemTableType;
DECLARE @sellInvoiceId UNIQUEIDENTIFIER = NEWID();
INSERT INTO @sellItems (item_barcode, warehouse_id, unit_id, amount, price)
VALUES 
    ('100001', 100, 10, 10, 120),
    ('100012', 101, 15, 1, 160);

EXEC usp_InsertSellingInvoiceWithDetails
    @sellInvoiceId,
    1,        
    5.00,	  --sale
    10.00,	  --vat
    3,        --quantity
    @sellItems;

select* from warehouse_items
