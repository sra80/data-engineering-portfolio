CREATE TABLE [db_sys].[infrastructure_types] (
    [ID]         INT           IDENTITY (0, 1) NOT NULL,
    [_type]      NVARCHAR (32) NOT NULL,
    [addedTSUTC] DATETIME2 (0) NOT NULL
);
GO

ALTER TABLE [db_sys].[infrastructure_types]
    ADD CONSTRAINT [PK__infrastructure_types] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

ALTER TABLE [db_sys].[infrastructure_types]
    ADD CONSTRAINT [DF__infrastructure_types__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO
