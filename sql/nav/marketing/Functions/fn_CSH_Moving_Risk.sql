CREATE function marketing.fn_CSH_Moving_Risk
    (
        @cus nvarchar(20),
        @csh_start date
    )

returns table

as

return

select case when s.is_active = 0 then null else case when h.[End Date] is null then round(1-db_sys.fn_divide(datediff(day,getutcdate(), dateadd(year,1,h.[Last Order])), datediff(day,h.[Last Order], dateadd(year,1,h.[Last Order])),default),4) else null end end risk_factor, case when s.is_active = 0 then null else case when h.[End Date] is null then datediff(day,getutcdate(), dateadd(year,1,h.[Last Order])) else null end end risk_days_left from ext.Customer_Status_History h join ext.Customer_Status s on h.[Status] = s.[ID] where h.No_ = @cus and h.[Start Date] = @csh_start
GO
