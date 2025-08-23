CREATE TABLE [ext].[Sales_Header] (
    [No_]                         NVARCHAR (20)    NOT NULL,
    [Document Type]               INT              NOT NULL,
    [Sell-to Customer No_]        NVARCHAR (40)    NOT NULL,
    [Order Date]                  DATE             NOT NULL,
    [Ship-to Country_Region Code] NVARCHAR (20)    NOT NULL,
    [Channel Code]                NVARCHAR (20)    NOT NULL,
    [Media Code]                  NVARCHAR (20)    NULL,
    [Payment Method Code]         NVARCHAR (20)    NOT NULL,
    [Currency Factor]             DECIMAL (20, 10) NULL,
    [Inbound Integration Code]    NVARCHAR (40)    NULL,
    [Origin Datetime]             DATETIME2 (0)    NULL,
    [dbo_checksum]                INT              NULL,
    [Created DateTime]            DATETIME2 (0)    NULL,
    [Sales Order Status]          INT              NULL,
    [Status]                      INT              NULL,
    [On Hold]                     NVARCHAR (3)     NULL,
    [External Document No_]       NVARCHAR (35)    NULL,
    [company_id]                  INT              NOT NULL,
    [customer_id]                 AS               ([hs_identity].[fn_Customer]([company_id],[Sell-to Customer No_])),
    [Created By ID]               INT              NULL,
    [Subscription No_]            NVARCHAR (20)    NULL,
    [outcode_id]                  INT              NULL,
    [customer_status]             INT              NULL,
    [id]                          INT              NULL,
    [hash_check]                  varbinary(16)    NULL
);
GO

ALTER TABLE [ext].[Sales_Header]
    ADD CONSTRAINT [FK__Sales_Header__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

ALTER TABLE [ext].[Sales_Header]
    ADD CONSTRAINT [FK__Sales_Header__outcode_id] FOREIGN KEY ([outcode_id]) REFERENCES [db_sys].[outcode] ([id]);
GO

CREATE NONCLUSTERED INDEX [IX__893]
    ON [ext].[Sales_Header]([Sell-to Customer No_] ASC, [Order Date] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__90E]
    ON [ext].[Sales_Header]([Sales Order Status] ASC)
    INCLUDE([Sell-to Customer No_], [Order Date]);
GO

CREATE NONCLUSTERED INDEX [IX__ED5]
    ON [ext].[Sales_Header]([Sell-to Customer No_] ASC);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__946]
    ON [ext].[Sales_Header]([id] ASC) where (id is not null);
GO

ALTER TABLE [ext].[Sales_Header]
    ADD CONSTRAINT [PK__Sales_Header] PRIMARY KEY CLUSTERED ([company_id] ASC, [No_] ASC, [Document Type] ASC);
GO

ALTER TABLE [ext].[Sales_Header]
    ADD CONSTRAINT [DF__Sales_Header__id] DEFAULT (next value for ext.sq_sales_header) for id
GO