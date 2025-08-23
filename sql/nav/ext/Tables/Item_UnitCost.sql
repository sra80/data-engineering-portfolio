CREATE TABLE [ext].[Item_UnitCost] (
    [item_ID]       INT           NOT NULL,
    [row_version]   INT           NOT NULL,
    [is_current]    BIT           NOT NULL,
    [addedTSUTC]    DATETIME2 (1) NOT NULL,
    [reviewedTSUTC] DATETIME2 (1) NOT NULL,
    [cost_actual]   FLOAT (53)    NOT NULL,
    [cost_forecast] FLOAT (53)    NOT NULL
);
GO

ALTER TABLE [ext].[Item_UnitCost]
    ADD CONSTRAINT [PK__Item_UnitCost] PRIMARY KEY CLUSTERED ([item_ID] ASC, [row_version] ASC);
GO

ALTER TABLE [ext].[Item_UnitCost]
    ADD CONSTRAINT [DF__Item_UnitCost__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO

ALTER TABLE [ext].[Item_UnitCost]
    ADD CONSTRAINT [DF__Item_UnitCost__reviewedTSUTC] DEFAULT (getutcdate()) FOR [reviewedTSUTC];
GO

ALTER TABLE [ext].[Item_UnitCost]
    ADD CONSTRAINT [DF__Item_UnitCost__is_current] DEFAULT ((0)) FOR [is_current];
GO
