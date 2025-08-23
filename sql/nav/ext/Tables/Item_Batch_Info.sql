CREATE TABLE [ext].[Item_Batch_Info] (
    [ID]           INT           IDENTITY (0, 1) NOT NULL,
    [company_id]   INT           NOT NULL,
    [sku]          NVARCHAR (20) NOT NULL,
    [variant_code] NVARCHAR (10) NOT NULL,
    [batch_no]     NVARCHAR (20) NOT NULL,
    [addedTSUTC]   DATETIME2 (1) NULL,
    [item_ID]      AS            ([ext].[fn_Item]([company_id],[sku])),
    [is_empty]     BIT           NOT NULL,
    [exp]          DATE          NULL,
    [ldd]          DATE          NULL,
    [unit_cost]    MONEY         NULL
);
GO

CREATE NONCLUSTERED INDEX [IX__FAD]
    ON [ext].[Item_Batch_Info]([is_empty] ASC)
    INCLUDE([variant_code]);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__942]
    ON [ext].[Item_Batch_Info]([company_id] ASC, [sku] ASC, [variant_code] ASC, [batch_no] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__80A]
    ON [ext].[Item_Batch_Info]([variant_code] ASC, [batch_no] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__95E]
    ON [ext].[Item_Batch_Info]([sku] ASC);
GO

CREATE NONCLUSTERED INDEX IX__D14
    ON [ext].[Item_Batch_Info] ([variant_code],[batch_no])
go

ALTER TABLE [ext].[Item_Batch_Info]
    ADD CONSTRAINT [PK__Item_Batch_Info] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

ALTER TABLE [ext].[Item_Batch_Info]
    ADD CONSTRAINT [DF__Item_Batch_Info__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO

ALTER TABLE [ext].[Item_Batch_Info]
    ADD CONSTRAINT [DF__Item_Batch_Info__is_empty] DEFAULT ((0)) FOR [is_empty];
GO

ALTER TABLE [ext].[Item_Batch_Info]
    ADD CONSTRAINT [FK__Item_Batch_Info__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO