CREATE TABLE [stock].[forecast_subscriptions] (
    [addedTSUTC]        DATETIME2 (3) NOT NULL,
    [row_version]       INT           NOT NULL,
    [rv_sub]            INT           NOT NULL,
    [location_id]       INT           NOT NULL,
    [item_id]           INT           NOT NULL,
    [ndd]               DATE          NOT NULL,
    [quantity]          INT           NOT NULL,
    [ringfenced]        INT           NOT NULL,
    [bis_qty]           INT           NOT NULL,
    [is_original]       BIT           NOT NULL
);
GO

CREATE NONCLUSTERED INDEX [IX__2FA]
    ON [stock].[forecast_subscriptions]([row_version] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__81B]
    ON [stock].[forecast_subscriptions]([item_id] ASC, [row_version] ASC, [ndd] ASC)
    INCLUDE([quantity], [ringfenced], [bis_qty]);
GO

CREATE NONCLUSTERED INDEX [IX__FD8]
    ON [stock].[forecast_subscriptions]([item_id] ASC, [ndd] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__4C9]
    ON [stock].[forecast_subscriptions]([item_id] ASC, [row_version] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__C01]
    ON [stock].[forecast_subscriptions]([location_id] ASC, [item_id] ASC, [ndd] ASC)
    INCLUDE([row_version]);
GO

CREATE NONCLUSTERED INDEX [IX__A8D]
    ON [stock].[forecast_subscriptions]([row_version] ASC)
    INCLUDE([quantity]);
GO

CREATE NONCLUSTERED INDEX [IX__37F]
    ON [stock].[forecast_subscriptions]([item_id] ASC, [ndd] ASC, [quantity] ASC);
GO

CREATE NONCLUSTERED INDEX IX__751
    ON [stock].[forecast_subscriptions] ([row_version],[item_id])
    INCLUDE ([addedTSUTC],[quantity],[ringfenced],[bis_qty],[is_original])
GO

CREATE NONCLUSTERED INDEX IX__267
ON [stock].[forecast_subscriptions] ([ndd])
INCLUDE ([quantity])
GO

CREATE NONCLUSTERED INDEX IX__08E
ON [stock].[forecast_subscriptions] ([rv_sub],[ndd])
GO

ALTER TABLE [stock].[forecast_subscriptions]
    ADD CONSTRAINT [PK__forecast_subscriptions] PRIMARY KEY CLUSTERED ([row_version] ASC, [rv_sub] ASC, [location_id] ASC, [item_id] ASC, [ndd] ASC);
GO

ALTER TABLE [stock].[forecast_subscriptions]
    ADD CONSTRAINT [FK__forecast_subscriptions__row_version] FOREIGN KEY ([row_version]) REFERENCES [stock].[forecast_subscriptions_version] ([row_version]);
GO

ALTER TABLE [stock].[forecast_subscriptions]
    ADD CONSTRAINT [DF__forecast_subscriptions__bis_qty] DEFAULT ((0)) FOR [bis_qty];
GO

ALTER TABLE [stock].[forecast_subscriptions]
    ADD CONSTRAINT [DF__forecast_subscriptions__rv_sub] DEFAULT ((0)) FOR [rv_sub];
GO

ALTER TABLE [stock].[forecast_subscriptions]
    ADD CONSTRAINT [DF__forecast_subscriptions__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO

ALTER TABLE [stock].[forecast_subscriptions]
    ADD CONSTRAINT [DF__forecast_subscriptions__is_original] DEFAULT (0) FOR [is_original];
GO

GRANT SELECT
    ON OBJECT::[stock].[forecast_subscriptions] TO [hs-bi-datawarehouse-df-anaplan]
GO