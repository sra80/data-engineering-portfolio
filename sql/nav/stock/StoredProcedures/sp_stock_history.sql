create procedure [stock].[sp_stock_history]
    (
        @closing_date date = null
    )

as

set nocount on

set ansi_warnings off

if @closing_date is null select @closing_date = dateadd(day,1,max(closing_date)) from [stock].[stock_history]

if @closing_date is null set @closing_date = dateadd(day,-7,sysdatetime())

while  @closing_date <= dateadd(day,-1,sysdatetime())

begin

        delete from stock.stock_history where closing_date = @closing_date

        insert into stock.stock_history (key_location, key_batch, closing_date, units)
        select
            loc.ID,
            ibi.ID,
            @closing_date,
            sum(Quantity)
        from
            hs_consolidated.[Item Ledger Entry] ile
        join
            ext.Item_Batch_Info ibi
        on
            (
                ile.company_id = ibi.company_id
            and ile.[Item No_] = ibi.sku
            and ile.[Variant Code] = ibi.variant_code
            and ile.[Lot No_] = ibi.batch_no
            )
        join
            ext.Location loc
        on
            (
                ile.company_id = loc.company_id
            and ile.[Location Code] = loc.location_code
            )
        where
            ( 
                ile.[Posting Date] <= @closing_date
            )
        group by
            loc.ID,
            ibi.ID
        having
            sum(Quantity) > 0

     set @closing_date = dateadd(day,1,@closing_date)

end
GO
