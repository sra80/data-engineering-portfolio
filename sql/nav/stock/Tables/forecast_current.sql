CREATE TABLE [stock].[forecast_current] (
    [_date]       DATE          NOT NULL,
    [location_id] INT           NOT NULL,
    [item_id]     INT           NOT NULL,
    [quantity]    FLOAT (53)    NOT NULL,
    [addTS]       DATETIME2 (3) NULL
);
GO

CREATE NONCLUSTERED INDEX [IX__16D]
    ON [stock].[forecast_current]([location_id] ASC, [item_id] ASC, [_date] ASC)
    INCLUDE([quantity]);
GO

CREATE NONCLUSTERED INDEX [IX__AC1]
    ON [stock].[forecast_current]([_date] ASC, [location_id] ASC, [item_id] ASC)
    INCLUDE([quantity]);
GO

CREATE NONCLUSTERED INDEX [IX__21B]
    ON [stock].[forecast_current]([location_id] ASC, [item_id] ASC, [_date] ASC, [quantity] ASC);
GO

GRANT INSERT
    ON OBJECT::[stock].[forecast_current] TO [hs-bi-datawarehouse-df-anaplan]
    AS [shaun];
GO

GRANT ALTER
    ON OBJECT::[stock].[forecast_current] TO [hs-bi-datawarehouse-df-anaplan]
    AS [shaun];
GO

ALTER TABLE [stock].[forecast_current]
    ADD CONSTRAINT [PK__forecast_current] PRIMARY KEY CLUSTERED ([_date] ASC, [location_id] ASC, [item_id] ASC);
GO

ALTER TABLE [stock].[forecast_current]
    ADD CONSTRAINT [DF__forecast_current__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO
