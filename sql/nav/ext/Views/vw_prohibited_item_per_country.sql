create view ext.vw_prohibited_item_per_country

as


with no_sell as
	(
	select
		p.[Country Code], i.No_ [Item No_]
	from
		[UK$Prohibited Item Per Country] p,[UK$Item] i
	where
		LEN(p.[Item No_]) = 0

	union

	select
		 [Country Code]
		,[Item No_]
	from
		[UK$Prohibited Item Per Country]
	where
		LEN([Item No_]) > 0
	)

, sell as
	(
	select
		c.Code [Country Code], i.No_ [Item No_]
	from
		[UK$Country_Region] c, [UK$Item] i
	)

, list_all as
	(
	select
		 [Country Code]
		,[Item No_]
		,'No' Prohibited
	from
		sell
	where
		not exists (select 1 from no_sell where sell.[Country Code] = no_sell.[Country Code] and sell.[Item No_] = no_sell.[Item No_])

	union all

	select
		 [Country Code]
		,[Item No_]
		,'Yes'
	from
		no_sell
	)

select
	 [Country Code]
	,[Item No_]
	,Prohibited
from
	list_all
GO
