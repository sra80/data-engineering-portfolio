CREATE TABLE [forecast_feed].[forecast_stage2] (
    [_year]          INT        NOT NULL,
    [_week]          INT        NOT NULL,
    [demand_channel] INT        NOT NULL,
    [_customer]      INT        NOT NULL,
    [sales_channel]  INT        NOT NULL,
    [_location]      INT        NOT NULL,
    [sku]            INT        NOT NULL,
    [quantity]       FLOAT (53) NULL
);
GO

CREATE NONCLUSTERED INDEX [IX__035]
    ON [forecast_feed].[forecast_stage2]([_year] ASC);
GO

GRANT ALTER
    ON OBJECT::[forecast_feed].[forecast_stage2] TO [hs-bi-datawarehouse-df-forecast_feed]
    AS [dbo];
GO
