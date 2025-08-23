create or alter view [marketing].[Customer]

as

select
    _root.ID key_cus,
    concat(case when nav.company_id = 1 then null else nav.company_id end,nav.nav_code) [ord_cus],
    case when ct.is_anon = 1 then cus.[Customer Type] else cus.[Name] end [Company],
    replace(typ.[Description],'B2B ','') collate SQL_Latin1_General_CP1_CI_AS [Customer Category],
    isnull(Platform.Platform+' ('+Platform.Country+')','Undefined') [First Platform],
    isnull(nullif(channel.[Description],''),'Unknown') [First Sales Channel],
    _root.first_order [First Order Date],
    country.[Name] Country,
    nullif(cus.[Default Channel Code],'') default_channel,
    case ct.is_retailAcc when 1 then 1 else 0 end retail_account,
    isnull((select top 1 1 from hs_consolidated.[Subscriptions Line] sl where nav.company_id = 1 and sl.[Customer No_] = nav.nav_code and sl.[Status] = 0),0) is_subscriber,
    isnull(cp.[Description],'Not Set') [Profile],
    cus.acorn_category,
    cus.acorn_description,
    cus.[Active Streak Date],
    cus.[Active Streak Year],
    cus.[Active Streak Years],
    cus.[Active Streak Months]
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
            cus.[Name],
            cus.[Country_Region Code],
            cus.[Default Channel Code],
            cus.[Profile],
            isnull(acorn.acorn_category,'99 Unknown') acorn_category,
            isnull(acorn.acorn_description,'99 Unknown') acorn_description,
            case when datediff(day,streak_last_order,getutcdate()) <= 365 then ec.streak_first_order end [Active Streak Date],
            case when datediff(day,streak_last_order,getutcdate()) <= 365 then year(ec.streak_first_order) end [Active Streak Year],
            case when datediff(day,streak_last_order,getutcdate()) <= 365 then floor(db_sys.fn_divide(datediff(day,ec.streak_first_order,ec.streak_last_order),365.25,default)+0.1) end [Active Streak Years],
            case when datediff(day,streak_last_order,getutcdate()) <= 365 then floor(db_sys.fn_divide(datediff(day,ec.streak_first_order,ec.streak_last_order),30.458333,default)+0.1) end [Active Streak Months]
        from
            [dbo].[UK$Customer] cus
        left join
            ext.Customer ec
        on
            (
                ec.company_id = 1
            and cus.No_ = ec.cus
            )
        outer apply
            ext.fn_Customer_Acorn(No_) acorn

        union all

        select
            4,
            'NL',
            cus.No_,
            cus.[Customer Type],
            cus.[Name],
            cus.[Country_Region Code],
            cus.[Default Channel Code],
            cus.[Profile],
            '99 Unknown',
            '99 Unknown',
            null [Active Streak Date],
            null [Active Streak Year],
            null [Active Streak Years],
            null [Active Streak Months]
        from
            [NL$Customer] cus

        union all

        select
            6 company_id,
            'IE',
            cus.No_ nav_code,
            cus.[Customer Type],
            cus.[Name],
            cus.[Country_Region Code],
            cus.[Default Channel Code],
            cus.[Profile],
            '99 Unknown',
            '99 Unknown',
            null [Active Streak Date],
            null [Active Streak Year],
            null [Active Streak Years],
            null [Active Streak Months]
        from
            [dbo].[IE$Customer] cus

        union all

        select
            5 company_id,
            'NZ',
            cus.No_ nav_code,
            cus.[Customer Type],
            cus.[Name],
            cus.[Country_Region Code],
            cus.[Default Channel Code],
            cus.[Profile],
            '99 Unknown',
            '99 Unknown',
            null [Active Streak Date],
            null [Active Streak Year],
            null [Active Streak Years],
            null [Active Streak Months]
        from
            [dbo].[NZ$Customer] cus
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
    ext.Platform
on
    _root.first_platform = Platform.ID
left join
    ext.Channel ec
on
    (
        _root.first_channel = ec.ID
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
        select
            1 company_id,
            [Code],
            [Description]
        from
            [dbo].[UK$Channel] t

        union all

        select
            4 company_id,
            [Code],
            [Description]
        from
            [dbo].[NL$Channel] t

        union all

        select
            6 company_id,
            [Code],
            [Description]
        from
            [dbo].[IE$Channel] t

        union all

        select
            5 company_id,
            [Code],
            [Description]
        from
            [dbo].[NZ$Channel] t
    ) channel
on
    (
        ec.company_id = channel.company_id
    and ec.Channel_Code = channel.Code
    )
join
    (
        select
            1 company_id,
            [Code],
            [Name]
        from
            [dbo].[UK$Country_Region] t

        union all

        select
            4,
            [Code],
            [Name]
        from
            [dbo].[NL$Country_Region] t

        union all

        select
            6,
            [Code],
            [Name]
        from
            [dbo].[IE$Country_Region] t

        union all

        select
            5,
            [Code],
            [Name]
        from
            [dbo].[NZ$Country_Region] t
    ) country
on
    (
        cus.company_id = country.company_id
    and isnull(nullif(cus.[Country_Region Code],''),cus.co_country) = country.Code
    )
left join
    (
        select
            [Code],
            [Description]
        from
            [dbo].[General Lookup]
        where
            (
                [Type] = 'PROFILE'
            )
    ) cp
on
    (
        cus.[Profile] = cp.[Code]
    )

union all

select 
    -ct.ID-1 key_cus,
    concat(case when typ.company_id = 1 then null else typ.company_id end,typ.Code) ord_cus,
 	typ.Code [Company],
 	replace(typ.[Description],'B2B ','') [Customer Category],
    null [First Platform],
    null [First Sales Channel],
    null [First Order Date],
    null [Country],
    null default_channel,
 	case ct.is_retailAcc when 1 then 1 else 0 end retail_account,
    0 is_subscriber,
    'Not Set' [Profile],
    '99 Unknown' acorn_category,
    '99 Unknown' acorn_description,
    null [Active Streak Date],
    null [Active Streak Year],
    null [Active Streak Years],
    null [Active Streak Months]
from
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
left join
  ext.Customer_Type ct
on
  (
      typ.company_id = ct.company_id
  and typ.Code = ct.nav_code
  )

GO
