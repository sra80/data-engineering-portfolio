create or alter function price_tool_feed.fn_build_test
    (
        @item_id int,
        @rrp money,
        @rrp_start date,
        @promo money,
        @promo_start date,
        @promo_end date
    )

returns table

as

return

select 'ArticleId;ZoneId;SiteId;Price;ValidFrom;ValidTo;Type' [value]

union all

select
    concat(@item_id,';',1,';',s.store_id,';',pl.Price,';',pl.ValidFrom,';',pl.ValidTo,';',pl.[Type])
from
    (select 1 store_id union all select 2 union all select 3) s
cross apply
    (
        
        select @promo Price, @promo_start ValidFrom, @promo_end ValidTo, 'default' [Type]
    
        union all

        select @rrp, @rrp_start, null, 'rrp'
            
    ) pl