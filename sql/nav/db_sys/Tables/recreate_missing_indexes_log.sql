CREATE TABLE [db_sys].[recreate_missing_indexes_log] (
    [ID]            INT            IDENTITY (1, 1) NOT NULL,
    [indexName]     NVARCHAR (64)  NOT NULL,
    [recreatedBy]   NVARCHAR (255) NOT NULL,
    [recreatedDate] DATETIME2 (0)  NOT NULL
);
GO

ALTER TABLE [db_sys].[recreate_missing_indexes_log]
    ADD CONSTRAINT [DF__recreate_missing_indexes_log__recreatedDate] DEFAULT (getutcdate()) FOR [recreatedDate];
GO

ALTER TABLE [db_sys].[recreate_missing_indexes_log]
    ADD CONSTRAINT [DF__recreate_missing_indexes_log__recreatedBy] DEFAULT (suser_sname()) FOR [recreatedBy];
GO

ALTER TABLE [db_sys].[recreate_missing_indexes_log]
    ADD CONSTRAINT [PK__recreate_missing_indexes_log] PRIMARY KEY CLUSTERED ([ID] ASC);
GO
