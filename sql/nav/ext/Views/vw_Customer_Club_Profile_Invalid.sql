create or alter view ext.vw_Customer_Club_Profile_Invalid

as

select
    co.Company,
    c.No_ [Customer Code],
    c.[Name]
from
    hs_consolidated.Customer c
join
    ext.Customer_Type ct
on
    (
        c.company_id = ct.company_id
    and c.[Customer Type] = ct.nav_code
    )
join
    db_sys.Company co
on
    (
        c.company_id = co.ID
    )
left join
    (
        select
            [Code]
        from
            [dbo].[General Lookup]
        where
            (
                [Type] = 'PROFILE'
            )
    ) cp
on
    (
        c.[Profile] = cp.[Code]
    )
cross apply
    (
        select top 1
            x.[Order Date]
        from
            (    
                select
                    h.[Order Date]
                from
                    ext.Sales_Header h
                where
                    (
                        c.company_id = h.company_id
                    and c.No_ = h.[Sell-to Customer No_]
                    and h.[Sales Order Status] = 1
                    )

                union all

                select
                    h.[Order Date]
                from
                    ext.Sales_Header_Archive h
                where
                    (
                        c.company_id = h.company_id
                    and c.No_ = h.[Sell-to Customer No_]
                    )

                union all

                select
                    h.[Order Date]
                from
                    ext.Sales_Header h
                join
                    hs_consolidated.[Media Code] mc
                on
                    (
                        h.company_id = mc.company_id
                    and h.[Media Code] = mc.[Code]
                    )
                where
                    (
                        c.company_id = h.company_id
                    and c.No_ = mc.[Customer No_]
                    and h.[Sales Order Status] = 1
                    )

                union all

                select
                    h.[Order Date]
                from
                    ext.Sales_Header_Archive h
                join
                    hs_consolidated.[Media Code] mc
                on
                    (
                        h.company_id = mc.company_id
                    and h.[Media Code] = mc.[Code]
                    )
                where
                    (
                        c.company_id = h.company_id
                    and c.No_ = mc.[Customer No_]
                    )
                    
            ) x
    ) lo
where
    (
        ct.ID_grp = 3
    and cp.Code is null
    )