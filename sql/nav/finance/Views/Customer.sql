create   view [finance].[Customer]

as

select 
    _root.ID keyCustomer,
    ec.ID keyCustomer_ID,
    case when ct.is_anon = 1 then cus.[Customer Type] else cus.[Name] end [Company],
    replace(typ.[Description],'B2B ','') collate SQL_Latin1_General_CP1_CI_AS [Customer Type],
    nav.nav_code [Customer],
    case ct.is_retailAcc when 1 then 'Yes' else 'No' end [B2B Account],
    _root.first_order [First Order Date],
    nc.[Nominal Code],
    isnull((select top 1 1 from hs_consolidated.[Subscriptions Line] sl where nav.company_id = 1 and sl.[Customer No_] = nav.nav_code and sl.[Status] = 0),0) is_subscriber
from 
    hs_identity_link.Customer _root
join
    hs_identity_link.Customer_NAVID nav
on
    (
        _root.nav_id_base = nav.ID
    )
join
    (
        select
            1 company_id,
            'GB' co_country,
            cus.No_ nav_code,
            cus.[Customer Type],
            cus.[Name]
        from
            [UK$Customer] cus

        union all

        select
            4,
            'NL',
            No_,
            [Customer Type],
            [Name]
        from
            [NL$Customer]

        union all

        select
            6 company_id,
            'IE',
            No_ nav_code,
            [Customer Type],
            [Name]
        from
            [dbo].[IE$Customer]

        union all

        select
            5 company_id,
            'NZ',
            No_ nav_code,
            [Customer Type],
            [Name]
        from
            [dbo].[NZ$Customer]
    ) cus
on
    (
        nav.company_id = cus.company_id
    and nav.nav_code = cus.nav_code 
    )
join
    ext.Customer_Type ct
on
    (
        cus.company_id = ct.company_id
    and cus.[Customer Type] = ct.nav_code
    )
left join
    ext.Customer ec
on
    (
        cus.company_id = ec.company_id
    and cus.nav_code = ec.cus
    )
left join
    (
        select
            1 company_id,
            [Code],
            [Description]
        from
            [dbo].[UK$Customer Type] t

        union all

        select
            4 company_id,
            [Code],
            [Description]
        from
            [dbo].[NL$Customer Type] t

        union all

        select
            6 company_id,
            [Code],
            [Description]
        from
            [dbo].[IE$Customer Type] t

        union all

        select
            5 company_id,
            [Code],
            [Description]
        from
            [dbo].[NZ$Customer Type] t
    ) typ
on
    (
            cus.company_id = typ.company_id
    and cus.[Customer Type] = typ.Code
    )
left join
    (
        select 1 company_id, nc.cus, concat(nc.G_L_Code,' - ',gla.[Name]) [Nominal Code] from finance.nominal_codes nc join [dbo].[UK$G_L Account] gla on nc.G_L_Code = gla.No_
    ) nc
on
    (
        cus.company_id = nc.company_id
    and cus.nav_code = nc.cus
    )
GO
