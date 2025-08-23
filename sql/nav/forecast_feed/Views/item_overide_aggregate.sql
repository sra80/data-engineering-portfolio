CREATE view [forecast_feed].[item_overide_aggregate]

as

select
    i.ID item_ID,
    min(i.ID) over (partition by i.No_) item_ID_overide
from
    ext.Item i
GO
