CREATE TABLE [forecast_feed].[sales_changes] (
    [key_date]           INT           NOT NULL,
    [key_demand_channel] INT           NOT NULL,
    [key_customer]       INT           NOT NULL,
    [key_sales_channel]  NVARCHAR (20) NOT NULL,
    [key_location]       INT           NOT NULL,
    [key_item]           DECIMAL (38)  NOT NULL,
    [units]              DECIMAL (38)  NOT NULL
);
GO

ALTER TABLE [forecast_feed].[sales_changes]
    ADD CONSTRAINT [PK__sales_changes] PRIMARY KEY CLUSTERED ([key_date] ASC, [key_demand_channel] ASC, [key_customer] ASC, [key_sales_channel] ASC, [key_location] ASC, [key_item] ASC);
GO

ALTER TABLE [forecast_feed].[sales_changes]
    ADD CONSTRAINT [DF__sales_changes__units] DEFAULT (0) FOR [units]
GO

CREATE NONCLUSTERED INDEX [IX__E4C]
    ON [forecast_feed].[sales_changes]([key_customer] ASC);
GO