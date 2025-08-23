CREATE TABLE [ext].[Sales_Archive] (
    [company_id]    INT   NOT NULL,
    [_date]         DATE  NOT NULL,
    [cus_type]      INT   NOT NULL,
    [country]       INT   NOT NULL,
    [channel]       INT   NOT NULL,
    [sku]           INT   NOT NULL,
    [quantity]      INT   NOT NULL,
    [vouchers]      MONEY NOT NULL,
    [gross_revenue] MONEY NOT NULL,
    [net_revenue]   MONEY NOT NULL
);
GO

ALTER TABLE [ext].[Sales_Archive]
    ADD CONSTRAINT [pk__Sales_Archive] PRIMARY KEY CLUSTERED ([company_id] ASC, [_date] ASC, [cus_type] ASC, [country] ASC, [channel] ASC, [sku] ASC);
GO

ALTER TABLE [ext].[Sales_Archive]
    ADD CONSTRAINT [df__Sales_Archive__net_revenue] DEFAULT ((0)) FOR [net_revenue];
GO

ALTER TABLE [ext].[Sales_Archive]
    ADD CONSTRAINT [df__Sales_Archive__gross_revenue] DEFAULT ((0)) FOR [gross_revenue];
GO

ALTER TABLE [ext].[Sales_Archive]
    ADD CONSTRAINT [df__Sales_Archive__quantity] DEFAULT ((0)) FOR [quantity];
GO

ALTER TABLE [ext].[Sales_Archive]
    ADD CONSTRAINT [df__Sales_Archive__vouchers] DEFAULT ((0)) FOR [vouchers];
GO

ALTER TABLE [ext].[Sales_Archive]
    ADD CONSTRAINT [FK__Sales_Archive__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO
