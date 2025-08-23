CREATE TABLE [forecast_feed].[sales] (
    [primary_key]        NVARCHAR (80) NOT NULL,
    [key_date]           INT           NOT NULL,
    [key_demand_channel] INT           NOT NULL,
    [key_customer]       INT           NOT NULL,
    [key_sales_channel]  NVARCHAR (20) NOT NULL,
    [key_location]       INT           NOT NULL,
    [key_item]           DECIMAL (38)  NOT NULL,
    [units]              DECIMAL (38)  NOT NULL,
    [units_adj]          INT           NULL,
    [auditLog_ID_insert] INT           NULL,
    [auditLog_ID_update] INT           NULL
);
GO

ALTER TABLE [forecast_feed].[sales]
    ADD CONSTRAINT [PK__sales] PRIMARY KEY CLUSTERED ([key_date] ASC, [key_demand_channel] ASC, [key_customer] ASC, [key_sales_channel] ASC, [key_location] ASC, [key_item] ASC);
GO

ALTER TABLE [forecast_feed].[sales]
    ADD CONSTRAINT [DF__sales__units] DEFAULT (0) FOR [units]
GO

CREATE NONCLUSTERED INDEX [IX__06E]
    ON [forecast_feed].[sales]([key_customer] ASC);
GO

alter table forecast_feed.sales add auditLog_ID_insert int null
go

alter table forecast_feed.sales add auditLog_ID_update int null
go

create index IX__F9E on forecast_feed.sales (auditLog_ID_update)
go