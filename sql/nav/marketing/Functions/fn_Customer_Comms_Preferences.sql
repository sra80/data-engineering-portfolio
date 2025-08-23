CREATE function [marketing].[fn_Customer_Comms_Preferences]
    (
        @cus nvarchar(32),
        @start date,
        @end date
    )

returns table

as

return
select
    x.opt_start,
    x.opt_end,
    x.cus,
    isnull(x.email,0) email,
    x.post,
    x.phone
from
    (
    select 
        n.[opt_start],
        isnull(dateadd(day,-1,lead(n.opt_start) over (partition by n.[Customer No_] order by n.opt_start)),getutcdate()) opt_end,
        n.[Customer No_] cus,
        case when EMAIL.[Status] = 0 then 1 else 0 end email,
        case when MAIL.[Status] = 0 then 1 else 0 end post,
        case when TEL.[Status] = 0 then 1 else 0 end phone
    from
        (
        select
            [opt_start],
            [Customer No_],
            [EMAIL],
            [MAIL],
            [TEL]
        from
            (
                select 
                    convert(date,[Modified DateTime]) [opt_start],
                    [Customer No_],
                    [Entry No_],
                    [Record Code]
                from
                    [UK$Customer Preferences Log]
                where
                    len([Customer No_]) > 0
            ) u
        pivot
            (
                max([Entry No_])
            for
                [Record Code] in ([EMAIL],[MAIL],[TEL])
            ) p
        ) n
    left join
        [UK$Customer Preferences Log] EMAIL
    on
        n.EMAIL = EMAIL.[Entry No_]
    left join
        [UK$Customer Preferences Log] MAIL
    on
        n.MAIL = MAIL.[Entry No_]
    left join
        [UK$Customer Preferences Log] TEL
    on
        n.TEL = TEL.[Entry No_]
    ) x
where
    (
        x.cus = @cus
    and x.opt_start >= @start
    and x.opt_end <= @end
    )
GO
