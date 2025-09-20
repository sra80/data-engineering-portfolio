create or alter procedure [db_sys].[sp_sales_marketplace_partner_check]

as

--check model is not actively running or disabled from processing
if not exists (select 1 from db_sys.process_model where model_name = 'Marketing_SalesOrders' and (process_active = 1 or disable_process = 1)) 

begin

	declare @ts_start varbinary(8), @ts_end varbinary(8), @rowcount int

	select @ts_start = last_timestamp from db_sys.timestamp_tracker where stored_procedure = 'db_sys.sp_sales_marketplace_partner_check' and table_name = '[dbo].[UK$Item Ledger Entry]'

	select 
		 @ts_end = isnull(max([timestamp]),0),
         @rowcount = isnull(sum(1),0)
	from
		[dbo].[UK$Item Ledger Entry]
	where
		[Location Code] in (select warehouse from finance.SalesInvoices_marketplace_partner)
	and [Entry Type] = 1
	and [Document Type] = 0
	and [timestamp] > @ts_start

    if @rowcount > 0

    begin

        exec db_sys.sp_auditLog_procedure @procedureName = 'ext.sp_External_Document_Number_marketplace_partner', @parent_procedureName = 'db_sys.sp_sales_marketplace_partner_check'

        update db_sys.process_model_partitions set process = 1 where model_name = 'Marketing_SalesOrders' and table_name = 'SalesOrders' and partition_name in ('Sales_marketplace_partner_00','Sales_marketplace_partner_01')

        update db_sys.timestamp_tracker set last_timestamp = @ts_end, last_update = getutcdate() where stored_procedure = 'db_sys.sp_sales_marketplace_partner_check' and table_name = '[dbo].[UK$Item Ledger Entry]'

    end

end
GO
