CREATE TABLE [ext].[Platform_Exceptions] (
    [order_no]   NVARCHAR (20) NOT NULL,
    [PlatformID] INT           NOT NULL,
    [AddedTSUTC] DATETIME2 (0) NOT NULL,
    [company_id] INT           NOT NULL
);
GO

ALTER TABLE [ext].[Platform_Exceptions]
    ADD CONSTRAINT [DF__Platform_Exceptions__AddedTSUTC] DEFAULT (getutcdate()) FOR [AddedTSUTC];
GO

ALTER TABLE [ext].[Platform_Exceptions]
    ADD CONSTRAINT [FK__Platform_Exceptions__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

ALTER TABLE [ext].[Platform_Exceptions]
    ADD CONSTRAINT [FK__Platform_Exceptions__PlatformID] FOREIGN KEY ([PlatformID]) REFERENCES [ext].[Platform] ([ID]);
GO

ALTER TABLE [ext].[Platform_Exceptions]
    ADD CONSTRAINT [PK__Platform_Exceptions] PRIMARY KEY CLUSTERED ([company_id] ASC, [order_no] ASC);
GO
