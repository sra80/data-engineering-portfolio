create or alter view [forecast_feed].[location_overide_aggregate]

as

select
    location_ID.company_id,
    location_ID_overide.company_id company_id_overide,
    n.location_id,
    n.location_ID_overide,
    location_ID.location_code,
    location_ID_overide.location_code location_code_overide,
    coalesce(location_ID.holding_loc,n.holding_loc,location_ID_overide.holding_loc) holding_loc,
    coalesce(location_ID.distribution_loc,n.distribution_loc,location_ID_overide.distribution_loc) distribution_loc,
    location_ID.default_loc,
    location_ID.subscription_loc
from
    (
        select
            l.ID location_id,
            isnull(manual_overide.location_ID_overide,overide.ID) location_ID_overide,
            manual_overide.holding_loc,
            manual_overide.distribution_loc
        from
            ext.Location l
        left join
            forecast_feed.location_overide manual_overide
        on
            (
                l.ID = manual_overide.location_ID
            )
        cross apply
            (
                select top 1 ID from ext.Location x where l.location_code = x.location_code order by company_id
            ) overide
    ) n
join
    ext.Location location_ID
on
    (
        n.location_id = location_ID.ID
    )
join
    (
        select
            ID,
            company_id,
            location_code,
            isnull(o.holding_loc,l.holding_loc) holding_loc,
            isnull(o.distribution_loc,l.distribution_loc) distribution_loc
        from
            ext.Location l
        left join
            forecast_feed.location_overide o
        on
            (
                l.ID = o.location_ID
            )
    ) location_ID_overide
on
    (
        n.location_ID_overide = location_ID_overide.ID
    )
GO
