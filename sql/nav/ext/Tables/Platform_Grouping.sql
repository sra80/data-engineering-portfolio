CREATE TABLE [ext].[Platform_Grouping] (
    [ID]             INT           IDENTITY (0, 1) NOT NULL,
    [Platform_Group] NVARCHAR (32) NOT NULL,
    [is_sub]         BIT           NOT NULL,
    [addTS]          DATETIME2 (3) NOT NULL
);
GO

ALTER TABLE [ext].[Platform_Grouping]
    ADD CONSTRAINT [PK__Platform_Grouping] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

ALTER TABLE [ext].[Platform_Grouping]
    ADD CONSTRAINT [DF__Platform_Grouping__is_sub] DEFAULT (0) FOR [is_sub];
GO

ALTER TABLE [ext].[Platform_Grouping]
    ADD CONSTRAINT [DF__Platform_Grouping__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__288]
    ON [ext].[Platform_Grouping]([Platform_Group] ASC);
GO