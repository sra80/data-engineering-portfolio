SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create or alter view [ext].[PickWall_Bins]

as

select
	bc.[Bin Code]
   ,bc.[Item No_] [Item No]
   ,bc.[Min_ Qty_] [Min Qty]
   ,bc.[Max_ Qty_] [Max Qty]
   ,sum(isnull(we.[Quantity],0)) [Available Bin Stock]
   ,case
		when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] = 1 then 11
        when bc.[Max_ Qty_] > 0 and sum(we.[Quantity]) < bc.[Max_ Qty_] and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] > 0.90 then 10
        when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] < 0.90 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] >= 0.80 then 9
        when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] < 0.80 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] >= 0.70 then 8
        when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] < 0.70 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] >= 0.60 then 7
		when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] < 0.60 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] >= 0.50 then 6
        when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] < 0.50 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] >= 0.40 then 5
        when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] < 0.40 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] >= 0.30 then 4
        when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] < 0.30 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] >= 0.20 then 3
        when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] < 0.20 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] >= 0.10 then 2
		when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] < 0.10 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] > 0 then 1
		when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] = 0 then 0
		when bc.[Max_ Qty_] > 0 and sum(we.[Quantity]) > bc.[Max_ Qty_] then 12
		when bc.[Max_ Qty_] = 0 then -2
	 else -1
	end 'ord_CapacityRange'
   ,case
		when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] = 1 then '100%'
        when bc.[Max_ Qty_] > 0 and sum(we.[Quantity]) < bc.[Max_ Qty_] and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] > 0.90 then 'Over 90%'
        when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] < 0.90 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] >= 0.80 then '90% - 80%'
        when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] < 0.80 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] >= 0.70 then '80% - 70%'
        when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] < 0.70 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] >= 0.60 then '70% - 60%'
		when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] < 0.60 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] >= 0.50 then '60% - 50%'
        when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] < 0.50 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] >= 0.40 then '50% - 40%'
        when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] < 0.40 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] >= 0.30 then '40% - 30%'
        when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] < 0.30 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] >= 0.20 then '30% - 20%'
        when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] < 0.20 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] >= 0.10 then '20% - 10%'
		when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] < 0.10 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] > 0 then 'Under 10%'
		when bc.[Max_ Qty_] > 0 and sum(isnull(we.[Quantity],0))/bc.[Max_ Qty_] = 0 then '0%'
		when bc.[Max_ Qty_] > 0 and sum(we.[Quantity]) > bc.[Max_ Qty_] then 'Overflowing'
		when bc.[Max_ Qty_] = 0 then 'Max Bin Quantity Undefined'
	 else 'Out of Scope'
	end 'Capacity Range'
	,case
		when bc.[Min_ Qty_] > sum(isnull(we.[Quantity],0)) then 'Yes'
		else 'No'
	end [Stock Below Minimum]
   ,isnull(sum(isnull(we.[Quantity],0))/nullif(bc.[Max_ Qty_],0),0) [Capacity Used]
   ,case
        when in_stock.[Item No_] is null then 'Yes'
        else 'No'
    end [OOS]
    ,isnull([WASDSP Stock],0) [WASDSP Stock]
from
	[NAV_PROD_REPL].[dbo].[UK$Bin Content] bc
left join
	[NAV_PROD_REPL].[dbo].[UK$Warehouse Entry] we
on
	(
		bc.[Location Code] = we.[Location Code]
	and bc.[Bin Code] = we.[Bin Code]
	and bc.[Item No_] = we.[Item No_]
	and bc.[Variant Code] = we.[Variant Code]
	and bc.[Unit of Measure Code] = we.[Unit of Measure Code]
	)
left join
    (
        select 
            [Item No_],
            [Inventory Quantity] - [Qty_ Ring Fenced] - [Qty_ in QC] [WASDSP Stock]
        from
            [dbo].[UK$Outbound Stock]
        where
            [Inventory Quantity] - [Qty_ Ring Fenced] - [Qty_ in QC] > 0
    ) in_stock
on
    (
        bc.[Item No_] = in_stock.[Item No_]
    )
where
	bc.[Zone Code] = 'PICKWALL'
group by
    bc.[Bin Code]
   ,bc.[Item No_] 
   ,bc.[Min_ Qty_] 
   ,bc.[Max_ Qty_]
   ,in_stock.[Item No_]
   ,[WASDSP Stock]

GO