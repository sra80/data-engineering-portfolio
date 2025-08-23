CREATE view [marketing].[Customer_Comms_Preferences]

as
select
    case when x.opt_end is null then 0 else year(getutcdate()) - year(x.opt_end) end model_partition,
    x.opt_start,
    isnull(x.opt_end,getutcdate()) opt_end,
    cus,
    email,
    post,
    phone,
    case when x.opt_end is null then 1 else 0 end is_current
from
    (
    select 
        n.[opt_start],
        dateadd(day,-1,lead(n.opt_start) over (partition by n.[Customer No_] order by n.opt_start)) opt_end,
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
GO
