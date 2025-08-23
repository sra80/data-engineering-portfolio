
create or alter view [stock].[Product]

as

with item_list as
	(
		select 
			e.ID key_sku,
			i.company_id,
            e.ID [Item ID],
            i.No_ [Item Code],
			isnull(nullif(i.[Description],''),i.No_) [Item Name],
			isnull(ic.[Description],'Not categorised') [Item Category],
			isnull([Range].[Name],'Not set') [Item Range],
			isnull([Global Dimension 2 Code] + ' - ' + [reportingGroup].[Name],'Not set') [Item Reporting Group],
			[Global Dimension 1 Code] + isnull(' - ' + entity.[Name],'') [Item Legal Entity],
			case [Status] when 0 then 'Prelaunch' when 1 then 'Active' when 2 then 'Discontinued' when 3 then 'Obsolete' when 4 then 'Rundown' else concat('Unknown Status (',[Status],')') end [Item Status],
			isnull(uom.[Description],'Unknown') [Unit of Measure],
			year(e.firstOrder) [First Order Year],
			e.firstOrder [First Order Date],
			ipg.[Description] [Inventory Posting],
			i.[Inventory Posting Group],
			case when fsai.No_ is null or len(fsai.fsai) = 0 then case when prohibit.[Item No_] is not null then 'Prohibited' else 'Unknown' end when fsai.fsai in ('no sales restrictions in Ireland','Food, no code required & can be sold in Ireland') then 'Not Required' else fsai.fsai end FSAI,
			-- row_number() over (partition by i.No_ order by i.No_) r,
            case when [Gen_ Prod_ Posting Group] = 'SERVICES' then 1 else 0 end [Service],
			case
				when i.[Packaging Type] = 'LARGELETTER' then 'Large Letter'
				when i.[Packaging Type] = 'PARCEL' then 'Parcel'
			 else i.[Packaging Type]
			 end [Packaging Type],
			i.[Item Tracking Code],
			i.[Daily Dose],
			i.[Pack Size],
			isnull(s.[Available Stock UK],0) [Available Stock UK],
			isnull(s.[Available Stock IE],0) [Available Stock IE],
            convert(money,round(nullif(icu.cost_actual,0),2)) [Actual Cost],
            convert(money,round(nullif(icu.cost_forecast,0),2)) [Forecast Cost]
		from
			[hs_consolidated].[Item] i
        join
            ext.Item e
        on
            (
                i.company_id = e.company_id
            and i.No_ = e.No_
            )
		left join
			[hs_consolidated].[Item Category] ic
		on
			(
                i.company_id = ic.company_id
            and i.[Item Category Code] = ic.Code
			)
		left join
			[hs_consolidated].[Dimension Value] [range]
		on
			(
                i.company_id = [range].company_id
            and i.[Range Code] = [range].[Code] 
			and [range].[Dimension Code] = 'RANGE'
			)
		left join
			[hs_consolidated].[Dimension Value] [reportingGroup]
		on
			(
                i.company_id = [reportingGroup].company_id
            and i.[Global Dimension 2 Code] = [reportingGroup].[Code] 
            and [reportingGroup].[Dimension Code] = 'REP.GRP'
			)
		left join
			[hs_consolidated].[Dimension Value] entity
		on
			(
                i.company_id = entity.company_id
            and i.[Global Dimension 1 Code] = entity.Code
			and entity.[Dimension Code] = 'ENTITY'
			)
		left join
			[hs_consolidated].[Unit of Measure] uom
		on
			(
                i.company_id = uom.company_id
            and i.[Base Unit of Measure] = uom.Code
			)
		left join
			[hs_consolidated].[Inventory Posting Group] ipg
		on
			(
                i.company_id = ipg.company_id
            and i.[Inventory Posting Group] = ipg.Code
			)
		left join
			(
			select
				iavm.company_id,
                iavm.No_,
				iav.[Value] fsai
			from
				hs_consolidated.[Item Attribute Value Mapping] iavm
			join
				hs_consolidated.[Item Attribute Value] iav
			on
				(
                    iavm.company_id = iav.company_id
                and iavm.[Item Attribute ID] = iav.[Attribute ID]
				and iavm.[Item Attribute Value ID] = iav.ID
				)
            join
                [hs_consolidated].[Item Attribute] ia
            on
                (
                    iavm.company_id = ia.company_id
                and	iavm.[Item Attribute ID] = ia.[ID]
                )
			where
				ia.[Name] = 'FSAI Code'
			) fsai
		on
			(
                i.company_id = fsai.company_id
            and i.No_ = fsai.No_
			)
		left join
			(
				select
					[Item No_]
				from
					ext.vw_prohibited_item_per_country
				where
					(
						[Country Code] = 'IE'
					and Prohibited = 'Yes'
					)
			) prohibit
		on
			i.No_ = prohibit.[Item No_]
		left join
			(
			select
			    [sku],
				sum(case when country = 'GB' then [openBalance] else 0 end) [Available Stock UK],
				sum(case when country = 'IE' then [openBalance] else 0 end) [Available Stock IE]
			from
				[ext].[Item_PLR]
			where
                (
                    is_current = 1
                and distribution_type = 'DIRECT'
                and country in ('GB','IE')
                )
			group by
				 [sku]
				-- ,[country]
			) s
		 on 
			(
                i.company_id = 1
            and i.[No_] = s.sku
			)
        left join
            ext.Item_UnitCost icu
        on
            (
                e.ID = icu.item_ID
            and icu.is_current = 1
            )
        -- outer apply
        --     (
        --         select top 1
        --             ax.cost
        --         from
        --             ext.Item_UnitCost_Actual ax
        --         where
        --             (
        --                 e.ID = ax.item_id
        --             )
        --         order by
        --             ax._date desc
        --     ) iua

	)

select
	i.[key_sku],
	i.[company_id],
    i.[Item Code],
    i.[Item ID],
    i.[Item Name],
	i.[Item Category],
	i.[Item Range],
	i.[Item Reporting Group],
	i.[Item Legal Entity],
	i.[Item Status],
	i.[Unit of Measure],
	i.[First Order Year],
	i.[First Order Date],
	i.[Inventory Posting],
	i.[Inventory Posting Group],
	i.[FSAI],
    i.[Service],
	i.[Packaging Type],
	i.[Item Tracking Code],
	i.[Daily Dose],
	i.[Pack Size],
	case
		when [Available Stock UK] + isnull(re.[Qty],0) < 0 then 0
		else [Available Stock UK] + isnull(re.[Qty],0) 
		end	[Available Stock UK],
	i.[Available Stock IE],
    i.[Actual Cost],
    i.[Forecast Cost]
from
	item_list i
left join --ringfenced stock deducted from avaialble stock in UK (currently stock only being ringfenced for WASDSP) 
	(
			select
				e.ID key_sku,
				-sum(convert(int,r.Quantity)) Qty	
			from
				hs_consolidated.[Ring Fencing Entry] r
            join
                ext.Item e
            on
                (
                    r.company_id = e.company_id
                and r.[Item No_] = e.No_
                )
			group by
				e.ID
			) re
		 on
			(
				i.[key_sku] = re.[key_sku]
			)
-- where
-- 	r = 1
GO
