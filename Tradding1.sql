CREATE DATABASE TraddingDB;
GO

USE TraddingDB;
GO

-- Brands
CREATE TABLE brands (
    id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100) NOT NULL UNIQUE
);

-- Categories
CREATE TABLE categories (
    id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100) NOT NULL UNIQUE
);

-- Measurement Header
CREATE TABLE measurement_header (
    um_id INT PRIMARY KEY IDENTITY(5,5),
    um_name NVARCHAR(50)
);

-- Measurement Details
CREATE TABLE measurement_details (
    unit_id INT PRIMARY KEY IDENTITY(5,5),
    unit_name NVARCHAR(50),
    equvilant INT NOT NULL,
    um_id INT,
    FOREIGN KEY (um_id) REFERENCES measurement_header(um_id)
);

-- Items
CREATE TABLE items (
    name VARCHAR(255) NOT NULL UNIQUE,
    barcode VARCHAR(100) PRIMARY KEY,
    category_id INT NOT NULL,
    brand_id INT NOT NULL,
    amount INT NOT NULL,
    purchase_price DECIMAL(10,2) NOT NULL,
    profit_rate DECIMAL(5,2),
    warning_percentage DECIMAL(5,2),
    selling_price AS (purchase_price * (1 + profit_rate)),
    FOREIGN KEY (category_id) REFERENCES categories(id),
    FOREIGN KEY (brand_id) REFERENCES brands(id)
);

-- Warehouses
CREATE TABLE warehousese (
    id INT PRIMARY KEY IDENTITY(100,1),
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT
);

-- Suppliers
CREATE TABLE suppliers (
    id INT PRIMARY KEY IDENTITY(200,1),
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT
);

-- Warehouse Items
CREATE TABLE warehouse_items (
    ware_id INT,
    item_barcode VARCHAR(100) NOT NULL,
    purchase_date DATE NOT NULL,
    purchase_price DECIMAL(10,2) NOT NULL,
    amount INT NOT NULL,
    expiration_date DATE,
    PRIMARY KEY (purchase_date, purchase_price, item_barcode),
    FOREIGN KEY (ware_id) REFERENCES warehousese(id),
    FOREIGN KEY (item_barcode) REFERENCES items(barcode)
);

-- Invoice Header
CREATE TABLE invoice_header (
    invoice_num UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    invoice_date DATE NOT NULL DEFAULT GETDATE(),
    invoice_time TIME DEFAULT CAST(GETDATE() AS TIME),
    supplier_id INT NOT NULL,
    sale_percentage DECIMAL(5,2),
    vat DECIMAL(5,2),
	quantaty_amount int NOT NULL,
    total_price  DECIMAL(15,2),
    FOREIGN KEY (supplier_id) REFERENCES suppliers(id)
);

-- Invoice Details (new structure replacing purchases_invoice)
CREATE TABLE invoice_details (
    invoice_detail_id INT IDENTITY(1,1) PRIMARY KEY,
    invoice_num UNIQUEIDENTIFIER NOT NULL,
    item_barcode VARCHAR(100) NOT NULL,
    warehouse_id INT NOT NULL,
    unit_id INT NOT NULL,
    amount INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,

    FOREIGN KEY (invoice_num) REFERENCES invoice_header(invoice_num),
    FOREIGN KEY (item_barcode) REFERENCES items(barcode),
    FOREIGN KEY (warehouse_id) REFERENCES warehousese(id),
    FOREIGN KEY (unit_id) REFERENCES measurement_details(unit_id)
);

CREATE TABLE customers (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    address NVARCHAR(255),
    created_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE selling_invoice_header (
    invoice_num UNIQUEIDENTIFIER PRIMARY KEY DEFAULT NEWID(),
    invoice_date DATE NOT NULL DEFAULT GETDATE(),
    invoice_time TIME DEFAULT CAST(GETDATE() AS TIME),
    customer_id INT NOT NULL,
    sale_percentage DECIMAL(5,2),
    vat DECIMAL(5,2),
    quantaty_amount INT NOT NULL,
    total_price DECIMAL(15,2),
    FOREIGN KEY (customer_id) REFERENCES customers(id)
);

CREATE TABLE selling_invoice_details (
    invoice_detail_id INT IDENTITY(1,1) PRIMARY KEY,
    invoice_num UNIQUEIDENTIFIER NOT NULL,
    item_barcode VARCHAR(100) NOT NULL,
    warehouse_id INT NOT NULL,
    unit_id INT NOT NULL,
    amount INT NOT NULL,
    price DECIMAL(10,2) NOT NULL,

    FOREIGN KEY (invoice_num) REFERENCES selling_invoice_header(invoice_num),
    FOREIGN KEY (item_barcode) REFERENCES items(barcode),
    FOREIGN KEY (warehouse_id) REFERENCES warehousese(id),
    FOREIGN KEY (unit_id) REFERENCES measurement_details(unit_id)
);
