




CREATE view [ext].[vw_Item_PLR]

as

select
	 c.[Name] [Country]
	,t.[Description] [Distribution Type]
	,b.[Inventory Posting]
	,case when b.[Item Status] in ('Discontinued','Obsolete') then 'Discontinued' when b.[Expiration Date] <= p.endDate then 'Expired' when b.[Latest Despatch Date] <= p.endDate then 'Past Latest Dispatch' else 'Saleable' end [Current Stock State]
	,case when b.[Item Status] in ('Discontinued','Obsolete') then 'Discontinued' when b.[Expiration Date] <= dateadd(day,7-DATEPART(dw,p.endDate),p.endDate) then 'Expiry Reached' when b.[Latest Despatch Date] <= dateadd(day,7-DATEPART(dw,p.endDate),p.endDate) then 'Latest Dispatch Reached' else 'Saleable' end [Stock State End of Week]
	,case when b.[Item Status] in ('Discontinued','Obsolete') then 'Discontinued' when b.[Expiration Date] <= EOMONTH(p.endDate) then 'Expiry Reached' when b.[Latest Despatch Date] <= EOMONTH(p.endDate) then 'Latest Dispatch Reached' else 'Saleable' end [Stock State End of Month]
	,b.[Item Range]
	,p.sku [Item Code]
	,b.[Item Name] [Item Description]
	,'Last Updated: '+format(dateadd(minute,datediff(minute,p.dateaddedUTC AT TIME ZONE isnull(tz_user.timezone,tz_default.timezone),p.dateaddedUTC),p.dateaddedUTC),'dd/MM/yyyy HH:mm') [Last Updated]
	,p.batchNo [Batch Number]
	,b.[Expiration Date]
	,b.[Latest Despatch Date]
	,case when DATEDIFF(week,p.endDate,b.[Latest Despatch Date]) < 0 then 0 else DATEDIFF(week,p.endDate,b.[Latest Despatch Date]) end [Weeks Remaining]
	,case when DATEDIFF(month,p.endDate,b.[Latest Despatch Date]) < 0 then 0 else DATEDIFF(month,p.endDate,b.[Latest Despatch Date]) end [Months Remaining]
	,p.unitCost [Unit Cost]
	,p.openBalance [Batch Quantity]
	,-CONVERT(decimal(9,3),ROUND(p.avgSalesDaily,3)) [Average Daily Sales]
	,p.closeBalance [Stock at Risk Quantity]
	,CONVERT(money,ROUND(p.unitCost*p.closeBalance,2)) [Stock at Risk Value]
	,case when b.[Expiration Date] <= EOMONTH(p.endDate) then 'Yes' else 'No' end [Expiration EOM]
	,case when b.[Expiration Date] <= dateadd(day,7-DATEPART(dw,p.endDate),p.endDate) then 'Yes' else 'No' end [Expiration EOW]
	,case when b.[Latest Despatch Date] <= EOMONTH(p.endDate) then 'Yes' else 'No' end [Latest Despatch EOM]
	,case when b.[Latest Despatch Date] <= dateadd(day,7-DATEPART(dw,p.endDate),p.endDate) then 'Yes' else 'No' end [Latest Despatch EOW]
	,case when DATEDIFF(month,p.endDate,b.[Latest Despatch Date]) <= 6 then 'Yes' else 'No' end [6 Month Window]
	,case when closeBalance > 0 then 'Yes' else 'No' end [Stock at Risk]
	,b.[Item Status]
	,case 
		when firstSale is null then
			case b.[Item Status] 
				when 'Active' then 'No Sales Yet'
				when 'Discontinued' then 'Never Sold'
				when 'Rundown' then 'Never Sold'
			else
				b.[Item Status]
			end
		when DATEDIFF(month,firstSale,endDate) <= 6 then '0-6 Months' 
		when DATEDIFF(month,firstSale,endDate) <= 12 then '6-12 Months'
	else
		case DATEDIFF(year,firstSale,endDate)
			when 1 then '1-2 Years'
			when 2 then '2-3 Years'
			when 3 then '3-4 Years'
			when 4 then '4-5 Years'
		else
			'5+ Years'
		end
	end [Sales Lifespan]
	,case 
		when DATEDIFF(month,endDate,[Latest Despatch Date]) < 0 then 'Past Latest Despatch' 
		when DATEDIFF(month,endDate,[Latest Despatch Date]) = 0 then 'Less than a Month' 
		when DATEDIFF(month,endDate,[Latest Despatch Date]) <= 6 then '1-6 Months' 
		when DATEDIFF(month,endDate,[Latest Despatch Date]) <= 12 then '6-12 Months'
	else
		case DATEDIFF(year,endDate,[Latest Despatch Date])
			when 1 then '1-2 Years'
			when 2 then '2-3 Years'
			when 3 then '3-4 Years'
			when 4 then '4-5 Years'
		else
			'5+ Years'
		end
	end [Batch Time Left]	
	,case when (firstSale is null or  DATEDIFF(month,firstSale,endDate) <= 6) and DATEDIFF(year,p.endDate,b.[Latest Despatch Date]) > 0 then 'Yes' else 'No' end [Low Risk & New] --remove later
	,dateadd(millisecond,-datepart(millisecond,p.dateaddedUTC),dateadd(second,-datepart(second,p.dateaddedUTC),dateadd(minute,datediff(minute,p.dateaddedUTC AT TIME ZONE isnull(tz_user.timezone,tz_default.timezone),p.dateaddedUTC),p.dateaddedUTC))) last_updated_sort
	,case when b.[Item Status] in ('Discontinued','Obsolete') then 3 when b.[Expiration Date] <= p.endDate then 2 when b.[Latest Despatch Date] <= p.endDate then 1 else 0 end [Current Stock State_sort]
	,case when b.[Item Status] in ('Discontinued','Obsolete') then 3 when b.[Expiration Date] <= dateadd(day,7-DATEPART(dw,p.endDate),p.endDate) then 2 when b.[Latest Despatch Date] <= dateadd(day,7-DATEPART(dw,p.endDate),p.endDate) then 1 else 0 end [Stock State End of week_sort]
	,case when b.[Item Status] in ('Discontinued','Obsolete') then 3 when b.[Expiration Date] <= EOMONTH(p.endDate) then 2 when b.[Latest Despatch Date] <= EOMONTH(p.endDate) then 1 else 0 end [Stock State End of month_sort]
	,case 
		when firstSale is null then
			case b.[Item Status] 
				when 'Active' then 7
				when 'Discontinued' then 8
				when 'Rundown' then 9
			else
				10
			end
		when DATEDIFF(month,firstSale,endDate) <= 6 then 0 
		when DATEDIFF(month,firstSale,endDate) <= 12 then 1
	else
		case DATEDIFF(year,firstSale,endDate)
			when 1 then 2
			when 2 then 3
			when 3 then 4
			when 4 then 5
		else
			6
		end
	end [Sales Lifespan_sort]
	,case 
		when DATEDIFF(month,endDate,[Latest Despatch Date]) < 0 then -1
		when DATEDIFF(month,endDate,[Latest Despatch Date]) = 0 then 0
		when DATEDIFF(month,endDate,[Latest Despatch Date]) <= 6 then 1
		when DATEDIFF(month,endDate,[Latest Despatch Date]) <= 12 then 2
	else
		case DATEDIFF(year,endDate,[Latest Despatch Date])
			when 1 then 3
			when 2 then 4
			when 3 then 5
			when 4 then 6
		else
			7
		end
	end [Batch Time Left_sort]
from
	ext.Item_PLR p
join
	[logistics].[ProductBatches] b
on
	(
		p.sku = b.key_sku
	and p.batchNo = b.[Batch Number]
	)
join
	[UK$Country_Region] c
on
	(
		p.country = c.Code
	)
join
	[UK$Customer Type] t
on
	(
		p.distribution_type = t.Code
	)
outer apply
	(
		select timezone from db_sys.user_config where lower(SYSTEM_USER) = lower(username) collate database_default
	) tz_user
outer apply
	(
		select timezone from db_sys.user_config where lower(SYSTEM_USER) = 'default' collate database_default
	) tz_default
where
	(
		p.is_current = 1
	)
GO
