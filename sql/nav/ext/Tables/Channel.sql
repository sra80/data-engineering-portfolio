CREATE TABLE [ext].[Channel] (
    [ID]                 INT           IDENTITY (1, 1) NOT NULL,
    [Channel_Code]       NVARCHAR (32) NOT NULL,
    [Group_Code]         INT           NOT NULL,
    [addedTSUTC]         DATETIME2 (1) NOT NULL,
    [company_id]         INT           NOT NULL,
    [is_visible_oos_plr] BIT           NOT NULL,
    [is_price_checked]   BIT           NOT NULL --ref e.g. ext.vw_sales_price_missing_eot
);
GO

ALTER TABLE [ext].[Channel]
    ADD CONSTRAINT [DF__Channel__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO

ALTER TABLE [ext].[Channel]
    ADD CONSTRAINT [DF__Channel__is_visible_oos_plr] DEFAULT ((0)) FOR [is_visible_oos_plr];
GO

ALTER TABLE [ext].[Channel]
    ADD CONSTRAINT [DF__Channel__is_price_checked] DEFAULT ((1)) FOR [is_price_checked];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__51D]
    ON [ext].[Channel]([company_id] ASC, [Channel_Code] ASC);
GO

ALTER TABLE [ext].[Channel]
    ADD CONSTRAINT [FK__Channel__Group_Code] FOREIGN KEY ([Group_Code]) REFERENCES [ext].[Channel_Grouping] ([Code]);
GO

ALTER TABLE [ext].[Channel]
    ADD CONSTRAINT [FK__Channel__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

ALTER TABLE [ext].[Channel]
    ADD CONSTRAINT [PK__Channel] PRIMARY KEY CLUSTERED ([ID] ASC);
GO