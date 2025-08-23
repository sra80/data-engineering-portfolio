CREATE TABLE [ext].[Packaging_Type] (
    [keyBox]         INT           NOT NULL,
    [box_type]       NVARCHAR (12) NOT NULL,
    [Packaging Type] NVARCHAR (20) NOT NULL,
    [insertedTSUTC]  DATETIME2 (0) NOT NULL,
    [updatedTSUTC]   DATETIME2 (0) NULL
);
GO

ALTER TABLE [ext].[Packaging_Type]
    ADD CONSTRAINT [Packaging_Type$0] PRIMARY KEY CLUSTERED ([keyBox] ASC);
GO

ALTER TABLE [ext].[Packaging_Type]
    ADD CONSTRAINT [DF__Packaging_Type__addedTSUTC] DEFAULT (sysdatetime()) FOR [insertedTSUTC];
GO
