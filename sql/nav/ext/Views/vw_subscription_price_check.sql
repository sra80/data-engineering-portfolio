create or alter view ext.vw_subscription_price_check

as

select
    SUBDEFAULT.[Item No_] [Item Code],
    format(SUBDEFAULT.[Unit Price],'c','en-GB') [SUBDEFAULT],
    format(fullprice.fullprice - fixed_discount.discount,'c','en-GB') [FULLPRICES Less Fixed Discount],
    format(promo.promo,'c','en-GB') [DEFAULT],
    concat(case when lowest_price.lowest_price > SUBDEFAULT.[Unit Price] then 'Increase' else 'Decrease' end,' SUBDEFAULT to ',format(lowest_price.lowest_price,'c','en-GB')) [Recommendation],
    case when i.[Subscribe and Save] = 1 then 'Yes' else 'No' end [Item Card S&S Enabled],
    isnull(ic_on.is_on,'No') [Repeat Channel Enabled]
from
    [UK$Sales Price] SUBDEFAULT
join
    [UK$Item] i
on
    (
        SUBDEFAULT.[Item No_] = i.No_
    )
cross apply
    (
        select
            min([Unit Price]) fullprice
        from
            [UK$Sales Price] f
        where
            (
                f.[Sales Type] = 1
            and f.[Sales Code] = 'FULLPRICES'
            and f.[Item No_] = SUBDEFAULT.[Item No_]
            and getutcdate() between f.[Starting Date] and f.[Ending Date]
            )
    ) fullprice
cross apply
    (
        select 
            max(discount.discount) discount
        from
            yieldigo.subs_fixed_discount discount
        where
            (
                fullprice.fullprice >= discount.price
            )          
    ) fixed_discount
outer apply
   (
        select
            min([Unit Price]) promo
        from
            [UK$Sales Price] f
        where
            (
                f.[Sales Type] = 1
            and f.[Sales Code] = 'DEFAULT'
            and f.[Item No_] = SUBDEFAULT.[Item No_]
            and getutcdate() between f.[Starting Date] and f.[Ending Date]
            )
    ) promo
cross apply
    (
        select
            min(price) lowest_price
        from
            (
                values
                    (fullprice.fullprice-fixed_discount.discount),
                    (promo.promo)
            )
                as
                    x(price)
    ) lowest_price
outer apply
    (
        select
            'Yes' is_on
        from
            [UK$Item Channel] ic
        where
            (
                SUBDEFAULT.[Item No_] = ic.[Item No_]
            and ic.[Channel Code] = 'REPEAT'
            )
    ) ic_on
where
    (
        SUBDEFAULT.[Sales Type] = 1
    and SUBDEFAULT.[Sales Code] = 'SUBDEFAULT'
    and getutcdate() between SUBDEFAULT.[Starting Date] and SUBDEFAULT.[Ending Date]
    and SUBDEFAULT.[Unit Price] != lowest_price.lowest_price
    and
        (
            ic_on.is_on = 'Yes'
        or  i.[Subscribe and Save] = 1
        )
    )