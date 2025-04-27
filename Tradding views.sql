CREATE VIEW v_suppliers_info
As
SELECT        suppliers.name, Sum(invoice_header.total_price) Price, sum(invoice_header.quantaty_amount) amount
FROM            invoice_header INNER JOIN
                         suppliers ON invoice_header.supplier_id = suppliers.id
GROUP BY suppliers.name

select * from v_suppliers_info

alter view v_items_in_warnning
as
SELECT        items.name item_name, Sum(items.amount) amount, warehousese.name AS ware_name, items.warning_percentage
FROM            items INNER JOIN
                         warehouse_items ON items.barcode = warehouse_items.item_barcode INNER JOIN
                         warehousese ON warehouse_items.ware_id = warehousese.id
GROUP BY items.name, warehousese.name , items.warning_percentage
having sum(items.amount) < items.warning_percentage

select * from v_items_in_warnning


alter view v_expired_items
as
SELECT        name item_name,expiration_date
FROM            items i join warehouse_items wi
on i.barcode = wi.item_barcode
where  DATEDIFF(DAY, GETDATE(), expiration_date) < 7

select * from v_expired_items

create view v_month_invoices
as 
select invoice_num,invoice_time,invoice_date,total_price
from invoice_header
where   MONTH(invoice_date) = MONTH(GETDATE()) AND
    YEAR(invoice_date) = YEAR(GETDATE());
select* from v_month_invoices

create view v_tradding_info
as
SELECT        items.name AS [item name], suppliers.name [supplier name], invoice_header.invoice_num, invoice_header.invoice_date, invoice_header.sale_percentage, invoice_header.vat, invoice_header.quantaty_amount, 
                         invoice_header.total_price
FROM            invoice_details INNER JOIN
                         invoice_header ON invoice_details.invoice_num = invoice_header.invoice_num INNER JOIN
                         items ON invoice_details.item_barcode = items.barcode INNER JOIN
                         suppliers ON invoice_header.supplier_id = suppliers.id

select* from v_tradding_info
