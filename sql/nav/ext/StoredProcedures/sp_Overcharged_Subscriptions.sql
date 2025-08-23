SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER  PROCEDURE [ext].[sp_Overcharged_Subscriptions]

as

set nocount on

--new [ext].[sp_Overcharged_Subscriptions]
/*

--(1)
new sp is operatinng under the assumption that going forward if Subscription Price Group on the Subscription Header table is not linked to the
price list, subscription job will error the subscription and it will not create a repeat order - this is to ensure that the Customer Price Group/
Price Group Code on the Sales Header/Sales Header Archive ALLWAYS matches the Subscription Price Group on the Subscription Header (e.g. it will prevent a 
scenario like on SO-13421226 where Price Group Code = DEFAULT, at the time the order was created it is possible to say that it was supposed to be PHMAR25
as that was the Subscription Price Group at the time and the underlying price list, but once the price holiday expires the Subscription Price Group will go back
to S&S£ and at that point there is no way to historically identify that it was suppose to be PHMAR25, it would then compare to SUBDEFAULT - all of the overcharged orders for PHMAR25 and PHMAR25_3
were inserted separately (script in #59483) at the time they were identified and Price Group was inserted based on Subscription Price Group and not Customer Price Group/
Price Group Code)

the sp will check the price for orders in the last three months, this is allowing for up to three months for the price to be identified as incorrect and modified,
and if the order is identified as overcharged it will be inserted into [ext].[Overcharged_Subscriptions], but if the price is modifed again, it will not update
the overcharged amount

the sp will insert the Collected Amount and Refunded Amount as 0 as default

--(2) the update will update Collected Amount and Refunded Amount across the board, this way the Payment/Refund table is only queried once and it will check/update
accordingly if/when the overcharges are resolved or even over refunded

--(3) is_resolved is updated to 1 for the ones where it is 0, and if [Overcharged Amount] <= [Refunded Amount] 

*/

--(1)
;with x as
(
    select
        sha.[Order Date]
        ,sha.[No_] [Order No]
        ,sha.[Subscription No_]	[Subscription No]
        ,sha.[Sell-to Customer No_]	[Customer No]
        ,sha.[Customer Price Group] [Price Group]
        ,coalesce(nullif(sla.[Originally Ordered No_],''),sla.[No_]) [Item No] --this is to check the price based on the bundle if it was a bundle and not the individual items
        ,sla.[Unit Price]
        ,sla.[Quantity]
        ,sla.[Amount Including VAT] [Gross Revenue Charged]
    from
        [dbo].[UK$Sales Header] sha--[ext].[Sales_Header_Archive] sha-- couldn't use ext table because I can't get the calculation of the Unit Price to work, if a discount is given on a sales order the calculation is overstating the price, e.g. SO-11369177
    join
        [dbo].[UK$Sales Line] sla--[ext].[Sales_Line_Archive] sla
    on
        (
                sha.[No_] = sla.[Document No_]
            and sha.[Document Type] = sla.[Document Type]
        )
    cross apply
        (
        select
            cpg.[code] [Customer Price Group]
        -- case 
        --     when cpg.[code] = 'SUBDEFAULT' then 'S&S£'
        --     else cpg.[code]
        -- end [Subscription Price Group] cpg
        from 
            [ext].[Customer_Price_Group] cpg 
        where 
            (
                    cpg.[is_ss] = 1
                and cpg.company_id = 1
                and sha.[Customer Price Group] = cpg.[code]
            )
        ) cpg
    where
        (
            sha.[Channel Code] = 'REPEAT'
        and sha.[Sales Order Status] = 1
        and sla.[Gen_ Prod_ Posting Group] = 'ITEM'
        and sha.[Order Date] > convert(date,dateadd(month, - 3,getutcdate()))
        )

    union

    select
        sha.[Order Date]
        ,sha.[No_] [Order No]
        ,sha.[Subscription No_]	[Subscription No]
        ,sha.[Sell-to Customer No_]	[Customer No]
        ,sha.[Price Group Code] [Price Group]
        ,coalesce(nullif(sla.[Originally Ordered No_],''),sla.[No_]) [Item No] --this is to check the price based on the bundle if it was a bundle and not the individual items
        ,sla.[Unit Price]
        ,sla.[Quantity]
        ,sla.[Amount Including VAT] [Gross Revenue Charged]
    from
        [dbo].[UK$Sales Header Archive] sha--[ext].[Sales_Header_Archive] sha-- couldn't use ext table because I can't get the calculation of the Unit Price to work, if a discount is given on a sales order the calculation is overstating the price, e.g. SO-11369177
    join
        [dbo].[UK$Sales Line Archive] sla--[ext].[Sales_Line_Archive] sla
    on
        (
                sha.[No_] = sla.[Document No_]
			and sha.[Document Type] = sla.[Document Type]
            and sha.[Doc_ No_ Occurrence] = sla.[Doc_ No_ Occurrence]
            and sha.[Version No_] = sla.[Version No_]
        )
    cross apply
        (
        select
            cpg.[code] [Customer Price Group]
        -- case 
        --     when cpg.[code] = 'SUBDEFAULT' then 'S&S£'
        --     else cpg.[code]
        -- end [Subscription Price Group] cpg
        from 
            [ext].[Customer_Price_Group] cpg 
        where 
            (
                    cpg.[is_ss] = 1
                and cpg.company_id = 1
                and sha.[Price Group Code] = cpg.[code]
            )
        ) cpg
    where
        (
            sha.[Channel Code] = 'REPEAT'
        and sha.[Archive Reason] = 3
        and sla.[Gen_ Prod_ Posting Group] = 'ITEM'
        and sha.[Order Date] > convert(date,dateadd(month, - 3,getutcdate()))
        )
)  

, y as
(
    select
		 x.[Order Date]
		,x.[Order No]
		,x.[Subscription No]
		,x.[Customer No]
		,x.[Item No]
		,x.[Quantity]
		,x.[Gross Revenue Charged]
		,x.[Quantity] * sp.[Unit Price] [Accurate Amount]
		,x.[Gross Revenue Charged] - (x.[Quantity] * sp.[Unit Price]) [Overcharged Amount]
        ,x.[Price Group]
	from
		x
	join
		[dbo].[UK$Sales Price] sp
	on
		(
			x.[Order Date] >= sp.[Starting Date]
		and x.[Order Date] <= sp.[Ending Date]
        and x.[Unit Price] > round(sp.[Unit Price],2)
        and x.[Item No] = sp.[Item No_]
	    and sp.[Sales Code] = x.[Price Group]
		)
)

insert into [ext].[Overcharged_Subscriptions] ([Order Date],[Order No],[Subscription No],[Customer No],[Item No],[Quantity],[Gross Revenue Charged],[Accurate Amount],[Overcharged Amount],[Collected Amount],[Refunded Amount],[Price Group])
select
     y.[Order Date]
	,y.[Order No]
	,y.[Subscription No]
    ,y.[Customer No]
    ,y.[Item No]
    ,y.[Quantity]
    ,y.[Gross Revenue Charged]
    ,y.[Accurate Amount]
    ,y.[Overcharged Amount]
    ,0 [Collected Amount]
    ,0 [Refunded Amount]
    ,y.[Price Group]
from 
    y
where
    y.[Overcharged Amount] > 0
and not exists (select 1 from [ext].[Overcharged_Subscriptions] os where os.[Order No] = y.[Order No])

--(2)
--update collected payments/refunds 
update e
set
   e.[Collected Amount] = pr.[Collected Amount]
  ,e.[Refunded Amount] = isnull(pr.[Refunded Amount],0)
from
	(
	select
		left([Payment Reference No_],11) [Payment Reference]
		,sum(case when [Type] = 3 then [Amount (LCY)] end) [Collected Amount]
	    ,sum(case when [Type] = 4 then [Amount (LCY)] end) [Refunded Amount]
	from
		[dbo].[UK$Payment_Refund] 
	where
		(
            [Type] in (3,4)
	    and [Processing Status] = 5
        )
	group by
		left([Payment Reference No_],11)
	) pr
join
	[ext].[Overcharged_Subscriptions] e
on	
	e.[Order No] = pr.[Payment Reference]

--(3)
--update is_resolved columns
update ext.[Overcharged_Subscriptions] 
set [is_resolved] = 1
where
    (
        [is_resolved] = 0
    and [Overcharged Amount] <= [Refunded Amount]
    )

GO