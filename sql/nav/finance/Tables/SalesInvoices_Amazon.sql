CREATE TABLE [finance].[SalesInvoices_Amazon] (
    [warehouse]     NVARCHAR (20) NOT NULL,
    [cus_code]      NVARCHAR (20) NOT NULL,
    [currency_code] NVARCHAR (3)  NOT NULL,
    [channel_code]  NVARCHAR (20) NOT NULL,
    [media_code]    NVARCHAR (20) NOT NULL,
    [addedTSUTC]    DATETIME2 (0) NOT NULL,
    [platformID]    INT           NOT NULL,
    [customer_id]   INT           NULL
);
GO

ALTER TABLE [finance].[SalesInvoices_Amazon]
    ADD CONSTRAINT [PK__SalesInvoices_Amazon] PRIMARY KEY CLUSTERED ([warehouse] ASC);
GO

ALTER TABLE [finance].[SalesInvoices_Amazon]
    ADD CONSTRAINT [DF__SalesInvoices_Amazon__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO
