create or alter function [ext].[fn_Customer_Status]
	(
		@company_id int,
        @cusCode nvarchar(32),
		@date date = null
	)

returns int

as

begin

declare @status int

set @date = isnull(@date,getutcdate())

if @company_id = 1

    begin

        select
            @status = [Status]
        from
            ext.Customer_Status_History s
        cross apply
            (select isnull(dateadd(day,-1,min([Start Date])),getutcdate()) [End Date] from ext.Customer_Status_History e where s.No_ = e.No_ and s.[Start Date] < e.[Start Date]) e
        where
            (
                s.No_ = @cusCode
            and s.[Start Date] <= @date
            and e.[End Date] >= @date
            )

        if @status is null select top 1 @status = customer_status from ext.fn_Customer_Status_History(@cusCode) where event_date <= @date order by event_date desc

    end

return isnull(@status,0)

end
GO
