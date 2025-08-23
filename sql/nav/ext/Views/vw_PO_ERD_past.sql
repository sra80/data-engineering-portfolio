create or alter view ext.vw_PO_ERD_past

as

select
    (select Company from db_sys.Company c where c.ID = ph.company_id) [HS Company],
    v.[Name] [Supplier],
    db_sys.fn_Lookup('Purchase Header','Status',ph.[Status]) [Status],
    db_sys.fn_Lookup('Purchase Header','Status 2',ph.[Status 2]) [Status 2],
    ph.No_ [PO Reference],
    pl.No_ [Item Code],
    convert(nvarchar,pl.[Expected Receipt Date],103) [Expected Receipt Date],
    format(pl.Quantity,'###,###,##0.####') [Original Quantity],
    format(pl.[Outstanding Quantity],'###,###,##0.####') [Oustanding Quantity]
from
    [hs_consolidated].[Purchase Header] ph
join
    [hs_consolidated].[Purchase Line] pl
on
    (
        ph.company_id = pl.company_id
    and ph.[Document Type] = pl.[Document Type]
    and ph.[No_] = pl.[Document No_]
    )
join
    [hs_consolidated].[Vendor] v
on
    (
        ph.company_id = v.company_id
    and ph.[Buy-from Vendor No_] = v.[No_]
    )
join
    hs_consolidated.Item hi
on
    (
        pl.company_id = hi.company_id
    and pl.[No_] = hi.[No_]
    )
join
    ext.Location l0
on
    (
        pl.company_id = l0.company_id
    and pl.[Location Code] = l0.location_code
    )
where
    (
        ph.[Document Type] = 1
    and ph.[Status] in (1,2,3)
    and ph.[Status 2] < 5
    and (
            (
                v.company_id = 1
            and v.[Type of Supply Code] = 'PROCUREMNT'
            )
        or
            (
                v.company_id > 1
            and v.[IC Partner Code] = 'HS SELL'
            )
        )
    and pl.[Type] = 2
    and pl.[Outstanding Quantity] > 0
    and pl.[Expected Receipt Date] < db_sys.foweek(getutcdate(),0)
    and pl.[Expected Receipt Date] > dateadd(year,-1,getutcdate()) 
    )