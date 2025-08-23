create or alter function ext.fn_Customer_Active_Streak
    (
        @cus nvarchar(20)
    )

returns table

as

return

select top 1
    isnull(csh_pre.[Start Date],csh.[Start Date]) first_order,
    csh.[Last Order] last_order
from
    ext.Customer_Status_History csh
join
    ext.Customer_Status cs
on
    (
        csh.[Status] = cs.ID
    )
outer apply
    (
        select top 1
            [Start Date],
            [Last Order]
        from
            ext.Customer_Status_History pre
        join
            ext.Customer_Status cf
        on
            (
                pre.[Status] = cf.ID
            )
        where
            (
                pre.No_ = csh.No_
            and cf.is_active = 1
            and datediff(day,pre.[End Date],csh.[Start Date]) between 0 and 14
            )
    ) csh_pre
where
    (
        csh.No_ = @cus
    and cs.is_active = 1
    )
order by
    csh.[Start Date] desc