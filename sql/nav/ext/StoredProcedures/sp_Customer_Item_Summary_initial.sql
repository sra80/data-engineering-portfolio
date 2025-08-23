create procedure ext.sp_Customer_Item_Summary_initial

as

declare @cus nvarchar(20)

declare [f0022ad6-0b5b-4a6a-9dac-91b248c142df] cursor for select No_ from [UK$Customer] where No_ not in (select cus from tmp.Customer_Item_Summary_fullload) 

open [f0022ad6-0b5b-4a6a-9dac-91b248c142df]

fetch next from [f0022ad6-0b5b-4a6a-9dac-91b248c142df] into @cus

while @@fetch_status = 0

begin

delete from ext.Customer_Item_Summary where cus = @cus

insert into ext.Customer_Item_Summary (cus,sku,units,gross,net,first_order,last_order)
select cus,sku,units,gross,net,first_order,last_order from ext.fn_Customer_Item_Summary(@cus,default)

insert into tmp.Customer_Item_Summary_fullload (cus) values (@cus)

fetch next from [f0022ad6-0b5b-4a6a-9dac-91b248c142df] into @cus

end

close [f0022ad6-0b5b-4a6a-9dac-91b248c142df]
deallocate [f0022ad6-0b5b-4a6a-9dac-91b248c142df]
GO
