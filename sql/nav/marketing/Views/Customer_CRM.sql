create or alter view [marketing].[Customer_CRM]

as

select
 	cus.No_ collate SQL_Latin1_General_CP1_CI_AS ord_cus,
 	case when ct.is_anon = 1 then cus.[Customer Type] else cus.[Name] end [Company],
 	replace(typ.[Description],'B2B ','') collate SQL_Latin1_General_CP1_CI_AS [Customer Category],
    isnull(Platform.Platform+' ('+Platform.Country+')','Undefined') [First Platform],
    isnull(nullif(channel.[Description],''),'Unknown') [First Sales Channel],
    ec.first_order_date [First Order Date],
    country.[Name] [Country],
    case when datediff(day,streak_last_order,getutcdate()) <= 365 then ec.streak_first_order end [Active Streak Date],
    case when datediff(day,streak_last_order,getutcdate()) <= 365 then year(ec.streak_first_order) end [Active Streak Year],
    case when datediff(day,streak_last_order,getutcdate()) <= 365 then floor(db_sys.fn_divide(datediff(day,ec.streak_first_order,ec.streak_last_order),365.25,default)+0.1) end [Active Streak Years],
    case when datediff(day,streak_last_order,getutcdate()) <= 365 then floor(db_sys.fn_divide(datediff(day,ec.streak_first_order,ec.streak_last_order),30.458333,default)+0.1) end [Active Streak Months],
    nullif(cus.[Default Channel Code],'') default_channel,
 	case ct.is_retailAcc when 1 then 1 else 0 end retail_account,
    isnull(acorn.acorn_category,'99 Unknown') acorn_category,
    isnull(acorn.acorn_description,'99 Unknown') acorn_description,
    isnull(subs.is_subscriber,0) is_subscriber
 from
 	[dbo].[UK$Customer] cus
 join
 	[dbo].[UK$Customer Type] typ
 on
    (
 	    cus.[Customer Type] = typ.Code
 	)
 left join
    (select * from ext.Customer where company_id = 1) ec
 on
    (
        cus.No_ = ec.cus
    )
 left join
    [dbo].[UK$Channel] channel
 on
    (
        ec.first_channel_code = channel.[Code]
    )
 left join
    ext.Platform
 on
    (
        ec.first_platformID = Platform.ID
    )
left join
    (
        select * from ext.Customer_Type where company_id = 1
    ) ct
on
    (
        typ.Code = ct.nav_code
    )
outer apply
    (
        select top 1 1 is_subscriber from [dbo].[UK$Subscriptions Line] s where s.[Status] = 0 and s.[Customer No_] = cus.No_
    ) subs
 outer apply
    ext.fn_Customer_Acorn(cus.No_) acorn
join
      [dbo].[UK$Country_Region] country
on
    isnull(nullif(cus.[Country_Region Code],''),'GB') = country.Code

 union all

 select
 	 typ.Code ord_cus
 	,typ.Code [Company]
 	,replace(typ.[Description],'B2B ','') [Customer Category]
     ,null [First Platform]
     ,null [First Sales Channel]
     ,null [First Order Date]
     ,null [Country]
     ,null [Active Streak Date]
     ,null [Active Streak Year]
     ,null [Active Streak Years]
     ,null [Active Streak Months]
     ,null default_channel
 	 ,case ct.is_retailAcc when 1 then 1 else 0 end retail_account
     ,null acorn_category
     ,null acorn_description
     ,null is_subscriber
 from
 	[dbo].[UK$Customer Type] typ
left join
    (select * from ext.Customer_Type where company_id = 1) ct
on
    (
        typ.Code = ct.nav_code
    )
GO
