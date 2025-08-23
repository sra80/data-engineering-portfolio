--ext.sp_External_Document_Number_Amazon (procedure) *done*
create   procedure ext.sp_External_Document_Number_Amazon

 as

 set nocount on

 declare @rowcount int = 1

 while @rowcount > 0

 begin

 insert into ext.External_Document_Number (company_id, [External Document No_])
 select distinct top 40000 
    1, [External Document No_] 
from 
    [dbo].[UK$Item Ledger Entry]
where 
    (
        len([External Document No_]) > 0 
    and [External Document No_] not in (select [External Document No_] from ext.External_Document_Number where company_id = 1) 
    and [Location Code] in (select warehouse from finance.SalesInvoices_Amazon)
    )

 set @rowcount = @@rowcount

 end
GO
