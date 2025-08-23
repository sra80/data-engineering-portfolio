CREATE TABLE [forecast_feed].[stage_forecast] (
    [_time]          NVARCHAR (255) NULL,
    [demand_channel] INT            NULL,
    [_customer]      INT            NULL,
    [sales_channel]  NVARCHAR (255) NULL,
    [_location]      INT            NULL,
    [sku]            INT            NULL,
    [quantity]       FLOAT (53)     NULL
);
GO

GRANT INSERT
    ON OBJECT::[forecast_feed].[stage_forecast] TO [hs-bi-datawarehouse-df-forecast_feed]
    AS [dbo];
GO

GRANT ALTER
    ON OBJECT::[forecast_feed].[stage_forecast] TO [hs-bi-datawarehouse-df-forecast_feed]
    AS [dbo];
GO
