
create   view [ext].[vw_brandMaker_sync]

as

with item_status (status_code, status_text) as
    (
            select 0 , 'Prelaunch'
        union
            select 1, 'Active'
        union
            select 2, 'Discontinued'
        union
            select 3, 'Obsolete'
        union
            select 4, 'Rundown'
    )
, ean as
    (
        select
             [Item No_] 
            ,[Cross-Reference No_] 
            ,[Variant Code]
            ,[Unit of Measure]
            ,[Cross-Reference Type]
            ,[Cross-Reference Type No_]
        from
            (
            select 
                [Item No_],
                [Cross-Reference No_],
                [Variant Code],
                [Unit of Measure],
                [Cross-Reference Type],
                [Cross-Reference Type No_],
                [timestamp],
                max([timestamp]) over (partition by [Item No_],[Variant Code],[Unit of Measure],[Cross-Reference Type],[Cross-Reference Type No_]) maxTimestamp
            from 
                [dbo].[UK$Item Cross Reference]
            where
                (
                    [Cross-Reference Type No_] = 'GS EAN13'
                and left([Cross-Reference No_],1) != '0'
                and [Discontinue Bar Code] = 0
                and [Cross-Reference Type] = 3
                )
            ) subQuery
        where
            (
                [timestamp] = maxTimestamp
            )
    )
, i_channel as
    (
        select 
            No_ [Item No_]
            ,
            substring
                (
                    (
      --                  select ','+c2.Code as [text()]
      --                  from dbo.Item_Channel (nolock) c1
						--join dbo.Channel (nolock) c2
						--on c1.[Channel Code] = c2.Code
      --                  where c1.[Item No_] = i.No_
      --                  order by c1.[Channel Code]
                     select distinct ',' + case 
		when patindex('B2B%',[Channel Code]) > 0 then 'B2B' 
		when patindex('WEB%',[Channel Code]) > 0 then 'WEB' 
		else [Channel Code] end as [text()]
	from 
		[dbo].[UK$Item Channel] c1 
	where 
		(
			[Channel Code] not in ('EXPOLINK','FAX','OOS DIVERT') 
		and len([Channel Code]) > 0
		and c1.[Item No_] = i.[No_]
		)
	order by 1
					 for xml path('')
                    )
                ,2,1024) [Channels]
        from
            [dbo].[UK$Item] (nolock) i
    )
, item_format as
    (
        select 
            iav.[Attribute ID]
            ,iav.ID
            ,iavm.[Table ID]
            ,iavm.[No_]
            ,[Item Attribute ID]
            ,iav.[Value]
        from 
            [dbo].[UK$Item Attribute Value] iav
        join
            [dbo].[UK$Item Attribute Value Mapping] iavm
        on
            (
                iav.[Attribute ID] = iavm.[Item Attribute ID]
            and iav.[ID] = iavm.[Item Attribute Value ID]
            )
        where
            iav.[Attribute ID] = 15
        and iavm.[Table ID] = 27
    )
, item_dietary_attributes as
    (
        select
            No_
            ,
            substring
                (
                    (
                        select ','+replace(replace(replace(d.[Dietary Code],'GELATINFRE','Gelatin Free'),'VEGAN','Vegan'),'VEGETARIAN','Vegetarian') as [text()]
                        from [dbo].[UK$Item Dietary Codes] d
                        where i.No_ = d.[Item No_]
                        order by d.[Dietary Code]
                        for xml path('')
                    )
                ,2,1024) item_dietary_attributes
        from
            [dbo].[UK$Item] i
    )
, item_prices as
    (
        select
            d.[Item No_],
            d.[Unit Price],
            d.[Unit Price] - isnull(s.[Unit Price],0) item_subscribe_saving
        from
            (
                select
                    [Item No_],
                    [Unit Price]
                from
                    (    
                        select 
                            [Item No_],
                            [Unit Price],
                            [timestamp],
                            max([timestamp]) over (partition by [Item No_]) maxTimestamp
                        from 
                            [dbo].[UK$Sales Price]
                        where
                            (
                                convert(date,[Starting Date]) <= convert(date,getutcdate())
                            and convert(date,[Ending Date]) >= convert(date,getutcdate())
                            and [Sales Type] = 1
                            and [Sales Code] = 'DEFAULT'
                            )
                    ) sp_default
                where
                    [timestamp] = maxTimestamp
            ) d
        left join
            (
                select
                    [Item No_],
                    [Unit Price]
                from
                    (    
                        select 
                            [Item No_]
                            ,[Unit Price]
                            ,[timestamp]
                            ,max([timestamp]) over (partition by [Item No_]) maxTimestamp
                        from 
                            [dbo].[UK$Sales Price]
                        where
                            (
                                convert(date,[Starting Date]) <= convert(date,getutcdate())
                            and convert(date,[Ending Date]) >= convert(date,getutcdate())
                            and [Sales Type] = 3
                            and [Sales Code] = 'SSDEFAULT'
                            )
                    ) ss_default
                where
                    [timestamp] = maxTimestamp
            ) s
        on
            (
                d.[Item No_] = s.[Item No_]
            )
    )
, final_data as
	(
	select
		 i.No_ item_sku
		,coalesce(nullif(i.[Description 2],''),nullif(i.[Description],''),'No Product Description') item_description
		,isnull(nullif(c.[Name],''),'Unknown') item_country_of_origin
		,isnull(nullif(r.[Description],''),'Unknown') item_range_description
		,isnull(nullif(i.[Range Code],''),'UNKNOWN') item_range_code
		,isnull(s.status_text,'Unknown') item_status
		,isnull(nullif(nullif(fsai.fsai,''),'Food, no code required & can be sold in Ireland'),'00000') FSAI
		,isnull(convert(int,round(i.[Pack Size],0)),0) item_pack_size
		,isnull(convert(decimal(6,3),round(i.[Gross Weight],3)),0) item_gross_weight
		,isnull(e.[Cross-Reference No_],'0000000000000') item_ean
		,isnull(h.Channels,'None') item_channels
		,isnull(f.[Value],'Unknown') item_format
		,isnull(convert(int,u.Width),0) item_width
		,isnull(convert(int,u.Height),0) item_height
		,isnull(convert(int,u.Length),0) item_length
		,i.[Net Weight] item_weight_net
		--,u.[Weight] item_weight_gross
		,isnull(d.item_dietary_attributes,'None') item_dietary_attributes
		,isnull(convert(money,p.[Unit Price]),0) item_default_price
		,isnull(convert(money,p.item_subscribe_saving),0) item_subscribe_saving
		,isnull(nullif(i.[Tariff No_],''),replicate('0',10)) commodity_code
	from
		[dbo].[UK$Item] i
	left join
		[dbo].[UK$Country_Region] c
	on
		(
			i.[Country_Region of Origin Code] = c.Code
		)
	left join
		[dbo].[UK$Range] r
	on
		(
			i.[Range Code] = r.Code
		)
	left join
		item_status s
	on
		(
			i.[Status] = s.status_code
		)
	left join
		ean e
	on
		(
			i.No_ = e.[Item No_]
		and i.[Base Unit of Measure] = e.[Unit of Measure]
		)
	left join
		i_channel h
	on
		(
			i.No_ = h.[Item No_]
		)
	left join
		item_format f
	on
		(
			f.No_ = i.No_
		)
	left join
		[dbo].[UK$Item Unit of Measure] u
	on
		(
			i.No_ = u.[Item No_]
		and i.[Base Unit of Measure] = u.Code
		)
	left join
		item_dietary_attributes d
	on  
		(
			i.No_ = d.No_
		)
	left join
		item_prices p
	on  
		(
			i.No_ = p.[Item No_]
		)
	left join
		(
			select
				 iavm.No_
				,iav.[Value] fsai
			from
				[dbo].[UK$Item Attribute Value Mapping] iavm
			join
				[dbo].[UK$Item Attribute Value] iav
			on
				(
					iavm.[Item Attribute ID] = iav.[Attribute ID]
				and iavm.[Item Attribute Value ID] = iav.ID
				)
			where
				[Item Attribute ID] = 32
		) fsai
	on
		(
			i.No_ = fsai.No_
		)
	)

select
	 item_sku
	,item_description
	,item_country_of_origin
	,item_range_description
	,item_range_code
	,item_status
	,FSAI
	,item_pack_size
	,item_gross_weight
	,item_ean
	,item_channels
	,item_format
	,item_width
	,item_height
	,item_length
	,item_weight_net
	--,item_weight_gross
	,item_dietary_attributes
	,item_default_price
	,item_subscribe_saving
	,commodity_code
	,checksum
		(
			 item_description
			,item_country_of_origin
			,item_range_description
			,item_range_code
			,item_status
			,FSAI
			,item_pack_size
			,item_gross_weight
			,item_ean
			,item_channels
			,item_format
			,item_width
			,item_height
			,item_length
			,item_weight_net
			--,item_weight_gross
			,item_dietary_attributes
			,item_default_price
			,item_subscribe_saving
			,commodity_code
		) bm_checksum
from
	final_data
GO
