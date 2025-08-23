CREATE TABLE [ext].[Sales_Header_Archive] (
    [Document Type]               INT              NOT NULL,
    [No_]                         NVARCHAR (20)    NOT NULL,
    [Doc_ No_ Occurrence]         INT              NOT NULL,
    [Version No_]                 INT              NOT NULL,
    [Sell-to Customer No_]        NVARCHAR (40)    NOT NULL,
    [Order Date]                  DATE             NOT NULL,
    [Ship-to Country_Region Code] NVARCHAR (20)    NOT NULL,
    [Channel Code]                NVARCHAR (20)    NOT NULL,
    [Media Code]                  NVARCHAR (20)    NULL,
    [Payment Method Code]         NVARCHAR (20)    NOT NULL,
    [Currency Factor]             DECIMAL (20, 10) NULL,
    [customer_status]             INT              NOT NULL,
    [Inbound Integration Code]    NVARCHAR (40)    NULL,
    [Order Created DateTime]      DATETIME2 (0)    NULL,
    [Origin Datetime]             DATETIME2 (0)    NULL,
    [External Document No_]       NVARCHAR (35)    NULL,
    [company_id]                  INT              NOT NULL,
    [customer_id]                 AS               ([hs_identity].[fn_Customer]([company_id],[Sell-to Customer No_])),
    [Created By ID]               INT              NULL,
    [Subscription No_]            NVARCHAR (20)    NULL,
    [outcode_id]                  INT              NULL,
    id                            INT              NULL,
    is_sid_processed              bit              NOT NULL, --has been processed through ext.sp_sales item doubles
    is_oqa_processed              bit              NOT NULL, --has been processed through ext.sp_OrderQueues_Archive
    is_csh_processed              bit              NOT NULL --has been processed through marketing.csh_item_range
);
GO

CREATE NONCLUSTERED INDEX [IX__C68]
    ON [ext].[Sales_Header_Archive]([External Document No_] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__FF5]
    ON [ext].[Sales_Header_Archive]([No_] ASC, [Document Type] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__F8F]
    ON [ext].[Sales_Header_Archive]([Order Date] ASC)
    INCLUDE([Ship-to Country_Region Code], [Channel Code], [Currency Factor], [Inbound Integration Code], [Order Created DateTime], [Origin Datetime]);
GO

CREATE NONCLUSTERED INDEX [IX__648]
    ON [ext].[Sales_Header_Archive]([Order Date] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__236]
    ON [ext].[Sales_Header_Archive]([company_id] ASC, [Sell-to Customer No_] ASC, [Order Date] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__C62]
    ON [ext].[Sales_Header_Archive]([No_] ASC, [Document Type] ASC, [Doc_ No_ Occurrence] ASC, [Version No_] ASC, [Sell-to Customer No_] ASC, [Order Date] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__34A]
    ON [ext].[Sales_Header_Archive]([company_id] ASC, [Order Date] ASC, [Sell-to Customer No_] ASC)
    INCLUDE([Channel Code], [No_], [Inbound Integration Code]);
GO

CREATE NONCLUSTERED INDEX [IX__530]
    ON [ext].[Sales_Header_Archive]([Sell-to Customer No_] ASC);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__9E4]
    ON [ext].[Sales_Header_Archive](id ASC) where (id is not null);
GO

CREATE NONCLUSTERED INDEX IX__ADF
ON [ext].[Sales_Header_Archive] ([Order Date])
INCLUDE ([id])
GO

create index IX__0BA on [ext].[Sales_Header_Archive] ([Media Code])
go

create index IX__703 on [ext].[Sales_Header_Archive] (is_sid_processed) where (is_sid_processed = 0)
go

create index IX__EFD on [ext].[Sales_Header_Archive] (is_oqa_processed) where (is_oqa_processed = 0)
go

CREATE NONCLUSTERED INDEX IX__EBD
ON [ext].[Sales_Header_Archive] ([is_oqa_processed])
INCLUDE ([id])
WHERE ([is_oqa_processed] = 0)
GO

create index IX__253 on ext.Sales_Header_Archive (is_csh_processed) include (company_id, [Sell-to Customer No_]) where (is_csh_processed = 0)
go

create index IX__85F on ext.Sales_Header_Archive (company_id, [Sell-to Customer No_])
go

ALTER TABLE [ext].[Sales_Header_Archive]
    ADD CONSTRAINT [FK__Sales_Header_Archive__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

ALTER TABLE [ext].[Sales_Header_Archive]
    ADD CONSTRAINT [FK__Sales_Header_Archive__outcode_id] FOREIGN KEY ([outcode_id]) REFERENCES [db_sys].[outcode] ([id]);
GO

ALTER TABLE [ext].[Sales_Header_Archive]
    ADD CONSTRAINT [PK__Sales_Header_Archive] PRIMARY KEY CLUSTERED ([company_id] ASC, [Document Type] ASC, [No_] ASC, [Doc_ No_ Occurrence] ASC, [Version No_] ASC);
GO

ALTER TABLE [ext].[Sales_Header_Archive]
    ADD CONSTRAINT [DF__Sales_Header_Archive__id] DEFAULT (next value for ext.sq_sales_header) for id
GO

ALTER TABLE [ext].[Sales_Header_Archive]
    ADD CONSTRAINT [DF__Sales_Header_Archive__is_sid_processed] DEFAULT 0 for is_sid_processed
GO

ALTER TABLE [ext].[Sales_Header_Archive]
    ADD CONSTRAINT [DF__Sales_Header_Archive__is_oqa_processed] DEFAULT 0 for is_oqa_processed
GO

ALTER TABLE [ext].[Sales_Header_Archive]
    ADD CONSTRAINT [DF__Sales_Header_Archive__is_csh_processed] DEFAULT 0 for is_csh_processed
GO
