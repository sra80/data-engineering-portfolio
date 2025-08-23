CREATE TABLE [forecast_feed].[forecast] (
    [row_version]    INT           NOT NULL,
    [is_current]     BIT           NOT NULL,
    [addedTSUTC]     DATETIME2 (1) NULL,
    [reviewedTSUTC]  DATETIME2 (1) NULL,
    [_year]          INT           NOT NULL,
    [_week]          INT           NOT NULL,
    [demand_channel] INT           NOT NULL,
    [_customer]      INT           NOT NULL,
    [sales_channel]  INT           NOT NULL,
    [_location]      INT           NOT NULL,
    [sku]            INT           NOT NULL,
    [quantity]       FLOAT (53)    NULL,
    [foweek]         DATE          NULL
);
GO

ALTER TABLE [forecast_feed].[forecast]
    ADD CONSTRAINT [DF__forecast__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO

ALTER TABLE [forecast_feed].[forecast]
    ADD CONSTRAINT [DF__forecast__reviewedTSUTC] DEFAULT (sysdatetime()) FOR [reviewedTSUTC];
GO

ALTER TABLE [forecast_feed].[forecast]
    ADD CONSTRAINT [DF__forecast__row_version] DEFAULT ((0)) FOR [row_version];
GO

ALTER TABLE [forecast_feed].[forecast]
    ADD CONSTRAINT [DF__forecast__is_current] DEFAULT ((1)) FOR [is_current];
GO

CREATE NONCLUSTERED INDEX [IX__A36]
    ON [forecast_feed].[forecast]([_location] ASC, [sku] ASC, [_year] ASC, [_week] ASC)
    INCLUDE([quantity]) WHERE ([is_current]=(1));
GO

CREATE NONCLUSTERED INDEX [IX__EE5]
    ON [forecast_feed].[forecast]([foweek] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__E19]
    ON [forecast_feed].[forecast]([sku] ASC, [quantity] ASC) WHERE ([is_current]=(1));
GO

CREATE NONCLUSTERED INDEX IX__8C1
ON [forecast_feed].[forecast] ([addedTSUTC])
GO

ALTER TABLE [forecast_feed].[forecast]
    ADD CONSTRAINT [PK__forecast] PRIMARY KEY CLUSTERED ([_year] ASC, [_week] ASC, [demand_channel] ASC, [_customer] ASC, [sales_channel] ASC, [_location] ASC, [sku] ASC, [row_version] ASC);
GO
