CREATE TABLE [ext].[Dimension_Value] (
    [ID]             INT           IDENTITY (0, 1) NOT NULL,
    [Dimension Code] NVARCHAR (20) NOT NULL,
    [Code]           NVARCHAR (20) NOT NULL,
    [addedTSUTC]     DATETIME2 (1) NULL
);
GO

ALTER TABLE [ext].[Dimension_Value]
    ADD CONSTRAINT [PK__Dimension_Value] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

ALTER TABLE [ext].[Dimension_Value]
    ADD CONSTRAINT [DF__Dimension_Value__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__F19]
    ON [ext].[Dimension_Value]([Dimension Code] ASC, [Code] ASC);
GO
