CREATE TABLE [ext].[Sales_Line_Archive] (
    [Document Type]             INT           NOT NULL,
    [Document No_]              NVARCHAR (20) NOT NULL,
    [Doc_ No_ Occurrence]       INT           NOT NULL,
    [Version No_]               INT           NOT NULL,
    [Line No_]                  INT           NOT NULL,
    [Location Code]             NVARCHAR (20) NULL,
    [Delivery Service]          NVARCHAR (40) NULL,
    [No_]                       NVARCHAR (40) NOT NULL,
    [Quantity]                  INT           NOT NULL,
    [Quantity Shipped]          INT           NOT NULL,
    [Quantity Invoiced]         INT           NOT NULL,
    [Promotion Discount Amount] MONEY         NOT NULL,
    [Line Discount Amount]      MONEY         NOT NULL,
    [Amount Including VAT]      MONEY         NOT NULL,
    [Amount]                    MONEY         NOT NULL,
    [ord_count]                 INT           NULL,
    [cost_center_code]          NVARCHAR (40) NULL,
    [Dimension Set ID]          INT           NULL,
    [company_id]                INT           NOT NULL,
    [id]                        INT           NULL,
    [sales_header_id]           INT           NULL,
    [Type]                      INT           NULL,
    [cis_id]                    INT           NULL --hs_identity.Customer_Item_Summary (id)
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__BD5]
    ON [ext].[Sales_Line_Archive]([id] ASC) WHERE ([id] IS NOT NULL);
GO

CREATE NONCLUSTERED INDEX [IX__32C]
    ON [ext].[Sales_Line_Archive]([Document Type] ASC, [Document No_] ASC, [Doc_ No_ Occurrence] ASC, [Version No_] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__974]
    ON [ext].[Sales_Line_Archive]([company_id] ASC, [Document No_] ASC, [Document Type] ASC, [Doc_ No_ Occurrence] ASC, [Version No_] ASC, [No_] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__E59]
    ON [ext].[Sales_Line_Archive]([Document No_] ASC, [Delivery Service] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__F94]
    ON [ext].[Sales_Line_Archive](company_id, [No_] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__375]
    ON [ext].[Sales_Line_Archive]([sales_header_id] ASC)
GO

CREATE NONCLUSTERED INDEX IX__096
    ON [ext].[Sales_Line_Archive] ([Quantity])
    INCLUDE ([No_],[sales_header_id])
GO

CREATE NONCLUSTERED INDEX IX__EEF
ON [ext].[Sales_Line_Archive] ([No_],[company_id],[Quantity])
INCLUDE ([sales_header_id])
GO

create index IX__034 on ext.Sales_Line_Archive (cis_id)
go

create index IX__81E on [ext].[Sales_Line_Archive] ([company_id], [Document No_], [No_], [Line No_])
go

ALTER TABLE [ext].[Sales_Line_Archive]
    ADD CONSTRAINT [PK__Sales_Line_Archive] PRIMARY KEY CLUSTERED ([company_id] ASC, [Document Type] ASC, [Document No_] ASC, [Doc_ No_ Occurrence] ASC, [Version No_] ASC, [Line No_] ASC);
GO

ALTER TABLE [ext].[Sales_Line_Archive]
    ADD CONSTRAINT [FK__Sales_Line_Archive__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

ALTER TABLE [ext].[Sales_Line_Archive]
    ADD [BOM Item No_] NVARCHAR (20) NULL
GO
