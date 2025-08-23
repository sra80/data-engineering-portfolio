CREATE TABLE [forecast_feed].[customer_exposure] (
    [is_type]     BIT           NOT NULL,
    [is_customer] BIT           NOT NULL,
    [is_d2c_agg]  BIT           NOT NULL,
    [ID]          INT           NOT NULL,
    [addTS]       DATETIME2 (3) NOT NULL,
    [is_excluded] BIT           NOT NULL
);
GO

ALTER TABLE [forecast_feed].[customer_exposure]
    ADD CONSTRAINT [CK__customer_exposure__is_type__is_d2c_agg] CHECK ([is_d2c_agg]=(0) AND [is_type]=(1) OR [is_d2c_agg]=(1) AND [is_type]=(1) OR [is_d2c_agg]=(0) AND [is_customer]=(1));
GO

ALTER TABLE [forecast_feed].[customer_exposure]
    ADD CONSTRAINT [CK__customer_exposure__is_type__is_customer] CHECK ([is_type]<>[is_customer]);
GO

ALTER TABLE [forecast_feed].[customer_exposure]
    ADD CONSTRAINT [DF__customer_exposure__is_type] DEFAULT ((0)) FOR [is_type];
GO

ALTER TABLE [forecast_feed].[customer_exposure]
    ADD CONSTRAINT [DF__customer_exposure__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO

ALTER TABLE [forecast_feed].[customer_exposure]
    ADD CONSTRAINT [DF__customer_exposure__is_d2c_agg] DEFAULT ((0)) FOR [is_d2c_agg];
GO

ALTER TABLE [forecast_feed].[customer_exposure]
    ADD CONSTRAINT [DF__customer_exposure__is_customer] DEFAULT ((0)) FOR [is_customer];
GO

ALTER TABLE [forecast_feed].[customer_exposure]
    ADD CONSTRAINT [DF__customer_exposure__is_excluded] DEFAULT ((0)) FOR [is_excluded];
GO

ALTER TABLE [forecast_feed].[customer_exposure]
    ADD CONSTRAINT [PK__customer_exposure] PRIMARY KEY CLUSTERED ([is_type] ASC, [is_customer] ASC, [ID] ASC);
GO
