create procedure ext.sp_Sales_Line_Amazon

as

insert into ext.Sales_Line_Amazon (ile_entry_no, sales_line_id)
select
    ile.[Entry No_],
    next value for ext.sq_sales_line
from
	[dbo].[UK$Item Ledger Entry] ile
join
    finance.SalesInvoices_Amazon amz
on
    (
        ile.[Location Code] = amz.warehouse
    )
where
    ile.[Entry No_] not in (select ile_entry_no from ext.Sales_Line_Amazon)
GO
