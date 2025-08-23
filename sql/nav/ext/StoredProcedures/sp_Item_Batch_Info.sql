create or alter procedure [ext].[sp_Item_Batch_Info]

as

set nocount on

insert into ext.Item_Batch_Info (company_id, sku, variant_code, batch_no)
select
    b.company_id,
    b.sku,
    b.variant_code,
    b.batch_no
from
    (
        select distinct
            ile.company_id,
            ile.[Item No_] sku,
            ile.[Variant Code] variant_code,
            ile.[Lot No_] batch_no
        from
            hs_consolidated.[Item Ledger Entry] ile
        where
            (
                len(ile.[Lot No_]) > 0
            )
    ) b
outer apply
    (
        select
            1 x
        from
            ext.Item_Batch_Info ibi
        where
            (
                b.company_id = ibi.company_id
            and b.sku = ibi.sku
            and b.variant_code = ibi.variant_code
            and b.batch_no = ibi.batch_no
            )
    ) x
where
    (
        x.x is null
    )

update
    ibi
set
    ibi.ldd = ile.ldd,
    ibi.[exp] = ile.exp
from
    (
        select
            ibi.ID,
            ibi.company_id,
            ibi.sku,
            ibi.variant_code,
            ibi.batch_no,
            ibi.[exp],
            ibi.ldd,
            i.[Item Tracking Code],
            i.[Daily Dose],
            i.[Pack Size]
        from
            ext.Item_Batch_Info ibi
        join
            hs_consolidated.Item i
        on
            (
                ibi.company_id = i.company_id
            and ibi.sku = i.No_
            )
        where
            (
                patindex('dummy',ibi.variant_code) = 0
            and len(ibi.batch_no) > 0
            and ibi.is_empty = 0
            and i.[Item Tracking Code] = 'LOTALLEXP'
            )
    ) ibi
outer apply
    (
        select top 1
            convert(date,ile.[Expiration Date]) exp,
            convert(date,ile.[Latest Despatch Date]) ldd
        from
            hs_consolidated.[Item Ledger Entry] ile
        where
            (
                ibi.company_id = ile.company_id
            and ibi.sku = ile.[Item No_]
            and ibi.variant_code = ile.[Variant Code]
            and ibi.batch_no = ile.[Lot No_]
            and ile.[Expiration Date] > datefromparts(1753,1,1)
            and ile.[Latest Despatch Date] > datefromparts(1753,1,1)
            )
        order by
            ile.[Entry No_] desc
    ) ile_ldd
outer apply
    (
        select top 1
            convert(date,ile.[Expiration Date]) exp,
            convert(date,isnull(nullif(ile.[Latest Despatch Date],datefromparts(1753,1,1)),nullif(dateadd(day,-(db_sys.fn_divide(ibi.[Pack Size],ibi.[Daily Dose],0)),ile.[Expiration Date]),ile.[Expiration Date]))) ldd
        from
            hs_consolidated.[Item Ledger Entry] ile
        where
            (
                ibi.company_id = ile.company_id
            and ibi.sku = ile.[Item No_]
            and ibi.variant_code = ile.[Variant Code]
            and ibi.batch_no = ile.[Lot No_]
            and ile.[Expiration Date] > datefromparts(1753,1,1)
            )
        order by
            ile.[Entry No_] desc
    ) ile_exp
cross apply
    (
        select
            isnull(ile_ldd.[exp],ile_exp.[exp]) exp,
            isnull(ile_ldd.[ldd],ile_exp.[ldd]) ldd
    ) ile
where
    (
        ibi.[exp] != ile.[exp]
    or  ibi.ldd != ile.ldd
    or
        (
            ibi.[exp] is null
        and ile.[exp] is not null
        )
    or
        (
            ibi.ldd is null
        and ile.ldd is not null
        )
    )

--batch unit cost ref ticket 48024 ***start
declare @place_holder uniqueidentifier = isnull((select place_holder from db_sys.procedure_schedule where procedureName = 'ext.sp_Item_Batch_Info' and process = 1),newid())

if (select sum(1) from cdc.Item_Batch_Info where cdc_instance = @place_holder) > 0 set @place_holder = newid()

insert into cdc.Item_Batch_Info (cdc_instance, id, unit_cost)
select
    @place_holder,
    ibi.ID,
    round(db_sys.fn_divide(ve.cost,q.Quantity,default),2) unit_cost
from
    ext.Item_Batch_Info ibi
cross apply
    (
        select
            max([Entry No_]) [Entry No_]
        from
            hs_consolidated.[Item Ledger Entry] ile
        where
            (
                ibi.company_id = ile.company_id
            and ibi.sku = ile.[Item No_]
            and ibi.variant_code = ile.[Variant Code]
            and ibi.batch_no = ile.[Lot No_]
            and ile.[Entry Type] in (0,2,4,6,9)
            )
    ) ile
cross apply
    (
        select
            Quantity
        from
            hs_consolidated.[Item Ledger Entry] ile2
        where
            (
                ibi.company_id = ile2.company_id
            and ile.[Entry No_] = ile2.[Entry No_]
            )
    ) q
cross apply
    (
        select sum(ve.[Cost Amount (Actual)])+sum(ve.[Cost Amount (Expected)]) cost from hs_consolidated.[Value Entry] ve left join hs_consolidated.[Purchase Line] pl on (ve.company_id = pl.company_id and ve.[Document No_] = pl.[Prod_ Order No_]) where isnull(pl.[Qty_ to Invoice],0) = 0 and ibi.company_id = ve.company_id and ile.[Entry No_] = ve.[Item Ledger Entry No_]
    ) ve
where
    (
        isnull(ibi.unit_cost,0) != round(db_sys.fn_divide(ve.cost,q.Quantity,default),2)
    and round(db_sys.fn_divide(ve.cost,q.Quantity,default),2) > 0
    )

update
    ibi
set
    ibi.unit_cost = cdc.unit_cost
from
    ext.Item_Batch_Info ibi
join
    cdc.Item_Batch_Info cdc
on
    (
        ibi.ID = cdc.id
    and cdc.cdc_instance = @place_holder
    )
--batch unit cost ref ticket 48024 ***end