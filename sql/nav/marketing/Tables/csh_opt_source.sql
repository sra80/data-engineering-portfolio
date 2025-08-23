CREATE TABLE [marketing].[csh_opt_source] (
    [id]               INT            IDENTITY (0, 1) NOT NULL,
    [opt_source]       NVARCHAR (255) NOT NULL,
    [opt_source_clean] NVARCHAR (255) NOT NULL,
    [addedTSUTC]       DATETIME2 (1)  NULL
);
GO

ALTER TABLE [marketing].[csh_opt_source]
    ADD CONSTRAINT [DF__csh_opt_source__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__D9C]
    ON [marketing].[csh_opt_source]([opt_source] ASC);
GO

ALTER TABLE [marketing].[csh_opt_source]
    ADD CONSTRAINT [PK__csh_opt_source] PRIMARY KEY CLUSTERED ([id] ASC);
GO
