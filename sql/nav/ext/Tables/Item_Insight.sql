CREATE TABLE [ext].[Item_Insight] (
    [child]  NVARCHAR (32) NOT NULL,
    [parent] NVARCHAR (32) NOT NULL,
    [scale]  INT           NOT NULL
);
GO

ALTER TABLE [ext].[Item_Insight]
    ADD CONSTRAINT [PK__Item_Insight] PRIMARY KEY CLUSTERED ([child] ASC);
GO
