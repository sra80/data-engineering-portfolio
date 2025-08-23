create function marketing.fn_CSH_Moving_Active_Start
    (
        @cus nvarchar(20)
    )

returns table

as

return

select min([Start Date]) active_from from ext.Customer_Status_History where No_ = @cus and [Start Date] > (select max([Start Date]) from ext.Customer_Status_History where No_ = @cus and [Status] in (select ID from ext.Customer_Status where is_active = 0))
GO
