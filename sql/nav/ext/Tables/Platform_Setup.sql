CREATE TABLE [ext].[Platform_Setup] (
    [Channel_Code]     NVARCHAR (32) NOT NULL,
    [Order_Prefix]     NVARCHAR (10) NOT NULL,
    [Integration_Code] NVARCHAR (32) NOT NULL,
    [PlatformID]       INT           NOT NULL,
    [AddedTSUTC]       DATETIME2 (0) NOT NULL,
    [company_id]       INT           NOT NULL
);
GO

ALTER TABLE [ext].[Platform_Setup]
    ADD CONSTRAINT [FK__Platform_Setup__PlatformID] FOREIGN KEY ([PlatformID]) REFERENCES [ext].[Platform] ([ID]);
GO

ALTER TABLE [ext].[Platform_Setup]
    ADD CONSTRAINT [DF__Platform_Setup__AddedTSUTC] DEFAULT (getutcdate()) FOR [AddedTSUTC];
GO

ALTER TABLE [ext].[Platform_Setup]
    ADD CONSTRAINT [PK__Platform_Setup] PRIMARY KEY CLUSTERED ([company_id] ASC, [Channel_Code] ASC, [Order_Prefix] ASC, [Integration_Code] ASC);
GO
