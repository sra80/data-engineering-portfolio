CREATE TABLE [ext].[Box_Type] (
    [ID]         INT           IDENTITY (1, 1) NOT NULL,
    [company_id] INT           NOT NULL,
    [box_type]   NVARCHAR (20) NOT NULL,
    [addedTSUTC] DATETIME2 (0) NOT NULL
);
GO

ALTER TABLE [ext].[Box_Type]
    ADD CONSTRAINT [PK__Box_Type] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

ALTER TABLE [ext].[Box_Type]
    ADD CONSTRAINT [DF__Box_Type__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO

ALTER TABLE [ext].[Box_Type]
    ADD CONSTRAINT [FK__Box_Type__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO
