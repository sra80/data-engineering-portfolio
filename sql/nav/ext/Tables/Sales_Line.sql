CREATE TABLE [ext].[Sales_Line] (
    [Document Type]             INT              NOT NULL,
    [Document No_]              NVARCHAR (20)    NOT NULL,
    [Line No_]                  INT              NOT NULL,
    [Location Code]             NVARCHAR (20)    NOT NULL,
    [No_]                       NVARCHAR (40)    NOT NULL,
    [Quantity]                  INT              NOT NULL,
    [Promotion Discount Amount] MONEY            NOT NULL,
    [Line Discount Amount]      MONEY            NOT NULL,
    [Amount Including VAT]      MONEY            NOT NULL,
    [Amount]                    MONEY            NOT NULL,
    [ord_count]                 INT              NULL,
    [Dimension Set ID]          INT              NULL,
    [Delivery Service]          NVARCHAR (40)    NULL,
    [Quantity Shipped]          INT              NULL,
    [Quantity Invoiced]         INT              NULL,
    [dbo_checksum]              INT              NULL,
    [company_id]                INT              NOT NULL,
    [id]                        INT              NULL,
    [sales_header_id]           INT              NULL,
    [Type]                      INT              NULL,
    [Outstanding Quantity]      DECIMAL (38, 20) NULL,
    hash_check                  varbinary(16)    NULL
);
GO

CREATE NONCLUSTERED INDEX [IX__704]
    ON [ext].[Sales_Line]([Document No_] ASC, [Delivery Service] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__055]
    ON [ext].[Sales_Line]([No_] ASC, [Outstanding Quantity] ASC)
    INCLUDE([Location Code], [id]);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__5AB]
    ON [ext].[Sales_Line]([id] ASC) WHERE ([id] IS NOT NULL);
GO

ALTER TABLE [ext].[Sales_Line]
    ADD CONSTRAINT [PK__Sales_Line] PRIMARY KEY CLUSTERED ([company_id] ASC, [Document Type] ASC, [Document No_] ASC, [Line No_] ASC);
GO

ALTER TABLE [ext].[Sales_Line]
    ADD CONSTRAINT [FK__Sales_Line__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

CREATE NONCLUSTERED INDEX IX__A83 ON [ext].[Sales_Line] ([Document No_],[Delivery Service],[company_id])
GO

CREATE INDEX IX__0B8 ON [ext].[Sales_Line] ([sales_header_id])
GO

CREATE NONCLUSTERED INDEX IX__DA3
ON [ext].[Sales_Line] ([Location Code],[company_id])
INCLUDE ([No_],[Quantity],[Dimension Set ID],[id])
GO

ALTER TABLE [ext].[Sales_Line]
    ADD [BOM Item No_] NVARCHAR (20) NULL
    
GO