CREATE TABLE [stock].[forecast_subscriptions_version] (
    [row_version] INT           NOT NULL,
    [addTS_start] DATETIME2 (3) NOT NULL,
    [addTS_end]   DATETIME2 (3) NOT NULL,
    [rv_sub_TS]   DATETIME2 (3) NULL,
    [is_current]  BIT           NOT NULL,
    [intraday_TS] DATETIME2 (3) NULL,
    [build_new_request] DATETIME2 (3) NULL
);
GO

ALTER TABLE [stock].[forecast_subscriptions_version]
    ADD CONSTRAINT [DF__forecast_subscriptions_version__addTS_end] DEFAULT (sysdatetime()) FOR [addTS_end];
GO

ALTER TABLE [stock].[forecast_subscriptions_version]
    ADD CONSTRAINT [DF__forecast_subscriptions_version__is_current] DEFAULT ((0)) FOR [is_current];
GO

ALTER TABLE [stock].[forecast_subscriptions_version]
    ADD CONSTRAINT [DF__forecast_subscriptions_version__addTS_start] DEFAULT (sysdatetime()) FOR [addTS_start];
GO

GRANT SELECT
    ON OBJECT::[stock].[forecast_subscriptions_version] TO [hs-bi-datawarehouse-df-anaplan]
    AS [shaun];
GO

ALTER TABLE [stock].[forecast_subscriptions_version]
    ADD CONSTRAINT [PK__forecast_subscriptions_version] PRIMARY KEY CLUSTERED ([row_version] ASC);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__7FD]
    ON [stock].[forecast_subscriptions_version]([is_current] ASC) WHERE ([is_current]=(1));
GO