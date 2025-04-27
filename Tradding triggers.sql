Create TRIGGER trg_after_insert_invoice_details
ON invoice_details
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    MERGE warehouse_items AS target
    USING (
        SELECT
            i.warehouse_id AS ware_id,
            i.item_barcode,
            CAST(GETDATE() AS DATE) AS purchase_date,  
            i.price / md.equvilant AS purchase_price,
            i.amount * md.equvilant AS amount
        FROM inserted i
        INNER JOIN measurement_details md ON i.unit_id = md.unit_id
    ) AS source
    ON target.purchase_date = source.purchase_date
        AND target.purchase_price = source.purchase_price
        AND target.item_barcode = source.item_barcode
        AND target.ware_id = source.ware_id
    WHEN MATCHED THEN
        UPDATE SET target.amount = target.amount + source.amount
    WHEN NOT MATCHED THEN
        INSERT (ware_id, item_barcode, purchase_date, purchase_price, amount, expiration_date)
        VALUES (source.ware_id, source.item_barcode, source.purchase_date, source.purchase_price, source.amount, NULL);
END;

ALTER TRIGGER trg_after_insert_update_warehouse_items
ON warehouse_items
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE i
    SET 
        i.amount = (
            SELECT SUM(wi.amount)
            FROM warehouse_items wi
            WHERE wi.item_barcode = i.barcode
        ),
        i.purchase_price = (
            SELECT TOP 1 wi.purchase_price
            FROM warehouse_items wi
            WHERE wi.item_barcode = i.barcode
            ORDER BY wi.purchase_date DESC
        )
    FROM items i
    WHERE i.barcode IN (SELECT DISTINCT item_barcode FROM inserted);
END;

ALTER TRIGGER trg_after_insert_selling_invoice_details
ON selling_invoice_details
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @barcode NVARCHAR(50),
            @ware_id INT,
            @converted_amount FLOAT,
            @available_amount FLOAT,
            @row_barcode NVARCHAR(50),
            @row_ware_id INT,
            @purchase_date DATE;

    -- Cursor to loop through inserted rows
    DECLARE inserted_cursor CURSOR FOR
        SELECT i.item_barcode, i.warehouse_id, i.amount * md.equvilant AS converted_amount
        FROM inserted i
        INNER JOIN measurement_details md ON i.unit_id = md.unit_id;

    OPEN inserted_cursor;

    FETCH NEXT FROM inserted_cursor INTO @barcode, @ware_id, @converted_amount;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Cursor to fetch warehouse items ordered by purchase_date (FIFO)
        DECLARE stock_cursor CURSOR FOR
            SELECT item_barcode, ware_id, amount, purchase_date
            FROM warehouse_items
            WHERE item_barcode = @barcode AND ware_id = @ware_id
            ORDER BY purchase_date;

        OPEN stock_cursor;

        FETCH NEXT FROM stock_cursor INTO @row_barcode, @row_ware_id, @available_amount, @purchase_date;

        WHILE @@FETCH_STATUS = 0 AND @converted_amount > 0
        BEGIN
            IF @available_amount >= @converted_amount
            BEGIN
                -- Subtract from stock
                UPDATE warehouse_items
                SET amount = amount - @converted_amount
                WHERE item_barcode = @row_barcode AND ware_id = @row_ware_id AND purchase_date = @purchase_date;

                -- Delete row if resulting amount is 0
                DELETE FROM warehouse_items
                WHERE item_barcode = @row_barcode AND ware_id = @row_ware_id AND purchase_date = @purchase_date AND amount = 0;

                SET @converted_amount = 0;
            END
            ELSE
            BEGIN
                -- Set amount to 0 if not enough stock
                UPDATE warehouse_items
                SET amount = 0
                WHERE item_barcode = @row_barcode AND ware_id = @row_ware_id AND purchase_date = @purchase_date;

                -- Delete row immediately since amount is 0
                DELETE FROM warehouse_items
                WHERE item_barcode = @row_barcode AND ware_id = @row_ware_id AND purchase_date = @purchase_date AND amount = 0;

                SET @converted_amount = @converted_amount - @available_amount;
            END

            FETCH NEXT FROM stock_cursor INTO @row_barcode, @row_ware_id, @available_amount, @purchase_date;
        END

        CLOSE stock_cursor;
        DEALLOCATE stock_cursor;

        -- Rollback if still need more stock than available
        IF @converted_amount > 0
        BEGIN
            RAISERROR('Not enough stock in the warehouse.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        FETCH NEXT FROM inserted_cursor INTO @barcode, @ware_id, @converted_amount;
    END

    CLOSE inserted_cursor;
    DEALLOCATE inserted_cursor;
END;
