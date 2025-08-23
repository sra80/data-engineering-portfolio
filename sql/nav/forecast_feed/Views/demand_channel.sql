
CREATE view [forecast_feed].[demand_channel]

as

select 
    ID key_demand_channel,
    Platform_Group [demand_channel]
from 
    ext.[Platform_Grouping]
GO
