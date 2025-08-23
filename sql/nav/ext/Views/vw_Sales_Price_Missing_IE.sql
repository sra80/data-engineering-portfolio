create or alter view ext.vw_Sales_Price_Missing_IE

as

--modified version of [ext].[Sales_Price_Missing]

select 
	i.[No_] [<p style="text-align:center;">Item Code</p>],
	i.[Description] [<p style="text-align:center;">Item Description</p>],
	isnull(d.is_available,'No') [<p style="text-align:center;">DEFAULTIE<br>Price</p>],
	isnull(f.is_available,'No') [<p style="text-align:center;">FULLPR-IE<br>Price</p>],
	case when i.[Subscribe and Save] = 1 then isnull(f.is_available,'No') else 'n/a' end [<p style="text-align:center;">SUBDEF-IE<br>Price</p>],
	case when row_number() over (order by i.[No_])%2 = 0 then '#D9E1F2' else '#FFFFFF' end bg
from 
	[IE$Item] i
outer apply
	(select top 1 'Yes' is_available from [IE$Sales Price] d where [Sales Code] = 'DEFAULTIE' and i.[No_] = d.[Item No_] and convert(date,[Starting Date]) <= convert(date,getutcdate()) and convert(date,[Ending Date]) >= convert(date,getutcdate())) d
outer apply
	(select top 1 'Yes' is_available from [IE$Sales Price] f where [Sales Code] = 'FULLPR-IE ' and i.[No_] = f.[Item No_] and convert(date,[Starting Date]) <= convert(date,getutcdate()) and convert(date,[Ending Date]) >= convert(date,getutcdate()))  f
outer apply
	(select top 1 'Yes' is_available from [IE$Sales Price] s where [Sales Code] = 'SUBDEF-IE ' and i.[No_] = s.[Item No_] and convert(date,[Starting Date]) <= convert(date,getutcdate()) and convert(date,[Ending Date]) >= convert(date,getutcdate())) s
where 
	(
        i.[Inventory Posting Group] = 'FINISHED' 
    and i.[Range Code] != 'WIDGETS' 
    and i.[Status] in (1)
    and 
        (
            d.is_available is null
        or  f.is_available is null
        or  
            (
                s.is_available is null 
            and  i.[Subscribe and Save] = 1
            )
        )
    )