create or alter procedure forecast_feed.sp_item_priority_class

as

set nocount on

declare @period date

declare @t table
    (
        _period date not null,
        item_id int not null,
        new_quantity int not null,
        sub_quantity int not null,
        all_quantity int not null,
        sale_cost money not null,
        sale_net money not null
    )

select
    @period = eomonth(isnull(dateadd(month,-2,max(_period)),datefromparts(year(getutcdate())-1,1,1)))
from
    forecast_feed.item_priority_class

while @period <= eomonth(getutcdate(),-1)

    begin

        insert into @t (_period, item_id, new_quantity, sub_quantity, all_quantity, sale_cost, sale_net)
        select
            @period,
            i.ID item_id,
            sum(case when d.[First Order Date] = convert(date,sih.[Order Date]) then -ve.[Invoiced Quantity] else 0 end),
            sum(case when sih.[Channel Code] = 'REPEAT' then -ve.[Invoiced Quantity] else 0 end),
            sum(-ve.[Invoiced Quantity]),
            sum(-ve.[Cost Posted to G_L]),
            sum(db_sys.fn_divide(sil.[Amount],isnull(nullif(sih.[Currency Factor],0),1),default))
        from
            [dbo].[UK$Value Entry] ve
        join
            [dbo].[UK$Sales Invoice Line] sil
        on
            (
                ve.[Document No_] = sil.[Document No_] 
            and ve.[Document Line No_] = sil.[Line No_]
            )
        join
            [dbo].[UK$Sales Invoice Header] sih
        on 
            (
                ve.[Document No_] = sih.[No_]
            )
        join
            ext.Sales_Invoice_Header esi
        on
            (
                esi.company_id = 1
            and esi.No_ = sih.No_
            )
        join
            ext.Item i
        on
            (
                i.company_id = 1 
            and i.No_ = sil.[No_]
            )
        join
            [dbo].[UK$Item] ii
        on
            (   
                ii.[No_] = sil.[No_]
            )
        cross apply
            hs_identity.fn_Customer_details(esi.customer_id) d
        where
            (
                ve.[Item Ledger Entry Type] = 1 
            and ve.[Document Type] = 2
            and ve.[Adjustment] = 0
            and eomonth(ve.[Posting Date]) = eomonth(@period)
            and ii.[Type] = 0
            )
        group by
            i.ID

        delete from forecast_feed.item_priority_class where eomonth(_period) = eomonth(@period)

        insert into forecast_feed.item_priority_class (_period, item_id, new_quantity, sub_quantity, all_quantity, sale_cost, sale_net)
        select
            _period, item_id, new_quantity, sub_quantity, all_quantity, sale_cost, sale_net
        from
            @t

        delete from @t

        set @period = eomonth(@period,1)

    end