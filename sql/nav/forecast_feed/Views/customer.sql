CREATE view [forecast_feed].[customer]

as

select
    key_cus,
    customer_name,
    customer_type
from
    (
        --customer types exposed
        select
            _root.ID key_cus,
            isnull(nullif(h_c.[Name],''),concat('BLANK IN NAV (',nav.nav_code,')')) customer_name,
            h_ct.[Description] customer_type
        from
            ext.Customer_Type ct
        join
            forecast_feed.customer_exposure ce
        on
            (

                ce.is_type = 1
            and ce.is_d2c_agg = 0
            and ce.is_excluded = 0
            and ct.ID = ce.ID
            and ct.is_anon = 0
            )
        join
            hs_consolidated.[Customer Type] h_ct
        on
            (
                ct.company_id = h_ct.company_id
            and ct.nav_code = h_ct.Code
            )
        join
        hs_consolidated.[Customer] h_c
        on
            (
                h_ct.company_id = h_c.company_id
            and h_ct.Code = h_c.[Customer Type]
            )
        join
            hs_identity_link.Customer_NAVID nav
        on
            (
                h_c.company_id = nav.company_id
            and h_c.No_ = nav.nav_code
            )
        join
            hs_identity_link.Customer _root
        on
            (
                nav.ID = _root.nav_id_base
            )

        union

        --customers exposed
        select
            _root.ID key_cus,
            isnull(nullif(h_c.[Name],''),concat('BLANK IN NAV (',nav.nav_code,')')) customer_name,
            h_ct.[Description] customer_type
        from
            forecast_feed.customer_exposure ce
        join
            hs_identity_link.Customer _root
        on
            (
                ce.is_customer = 1
            and ce.is_excluded = 0
            and ce.ID = _root.ID
            )
        join
            hs_identity_link.Customer_NAVID nav
        on
            (
                _root.nav_id_base = nav.ID
            )
        join
            hs_consolidated.Customer h_c
        on
            (
                nav.company_id = h_c.company_id
            and nav.nav_code = h_c.No_
            )
        join
            hs_consolidated.[Customer Type] h_ct
        on
            (
                h_c.company_id = h_ct.company_id
            and h_c.[Customer Type] = h_ct.Code
            )
        join
            ext.Customer_Type ct
        on
            (
                h_ct.company_id = ct.company_id
            and h_ct.Code = ct.nav_code
            and ct.is_anon = 0
            )

        union

        --customer types not exposed, not excluded and not aggregated to d2c
        select
            -ct.ID-1,
            h_ct.[Description],
            h_ct.[Description]
        from
            ext.Customer_Type ct
        join
            hs_consolidated.[Customer Type] h_ct
        on
            (
                ct.company_id = h_ct.company_id
            and ct.nav_code = h_ct.Code
            )
        left join
            forecast_feed.customer_exposure ce
        on
            (
                ce.is_type = 1
            and ct.ID = ce.ID
            )
        where
            (
                ct.ID = ct.ID_grp
            and ce.ID is null
            )

        union

        --customer types no exposed and aggregated
        select
            -1000,
            'Direct to Consumer',
            'Direct to Consumer'
        from
            ext.Customer_Type ct
        join
            forecast_feed.customer_exposure ce
        on
            (
                ce.is_type = 1
            and ce.is_d2c_agg = 1
            and ce.is_excluded = 0
            and ct.ID = ce.ID
            )
        join
            hs_consolidated.[Customer Type] h_ct
        on
            (
                ct.company_id = h_ct.company_id
            and ct.nav_code = h_ct.Code
            )
    ) c
where
    (
        c.key_cus in (select key_customer from forecast_feed.sales)
    )
GO
