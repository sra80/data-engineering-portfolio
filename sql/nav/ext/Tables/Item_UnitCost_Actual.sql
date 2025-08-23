CREATE TABLE [ext].[Item_UnitCost_Actual] (
    [_date]   DATE  NOT NULL,
    [item_id] INT   NOT NULL,
    [cost]    MONEY NULL
);
GO

ALTER TABLE [ext].[Item_UnitCost_Actual]
    ADD CONSTRAINT [PK__Item_UnitCost_Actual] PRIMARY KEY CLUSTERED ([_date] ASC, [item_id] ASC);
GO
