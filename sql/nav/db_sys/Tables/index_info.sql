CREATE TABLE [db_sys].[index_info] (
    [indexName]   NVARCHAR (64)  NOT NULL,
    [tableName]   NVARCHAR (64)  NOT NULL,
    [projectID]   INT            NOT NULL,
    [script]      NVARCHAR (MAX) NULL,
    [info]        NVARCHAR (MAX) NULL,
    [createdBy]   NVARCHAR (255) NOT NULL,
    [createdDate] DATETIME2 (0)  NOT NULL,
    [updatedBy]   NVARCHAR (255) NULL,
    [updatedDate] DATETIME2 (0)  NULL,
    [deletedBy]   NVARCHAR (255) NULL,
    [deletedDate] DATETIME2 (0)  NULL,
    [errorBlock]  BIT            NOT NULL
);
GO

ALTER TABLE [db_sys].[index_info]
    ADD CONSTRAINT [DF__createdDate] DEFAULT (getutcdate()) FOR [createdDate];
GO

ALTER TABLE [db_sys].[index_info]
    ADD CONSTRAINT [DF__createdBy] DEFAULT (lower(suser_sname())) FOR [createdBy];
GO

ALTER TABLE [db_sys].[index_info]
    ADD CONSTRAINT [DF__projectID] DEFAULT ((0)) FOR [projectID];
GO

ALTER TABLE [db_sys].[index_info]
    ADD CONSTRAINT [DF__indexName] DEFAULT ([db_sys].[fn_index_info_indexName]()) FOR [indexName];
GO

ALTER TABLE [db_sys].[index_info]
    ADD CONSTRAINT [DF__index_info__errorBlock] DEFAULT ((0)) FOR [errorBlock];
GO

ALTER TABLE [db_sys].[index_info]
    ADD CONSTRAINT [PK__index_info] PRIMARY KEY CLUSTERED ([indexName] ASC);
GO

CREATE trigger [db_sys].[index_info__update] on [db_sys].[index_info]

for update, insert

as

begin

set nocount on

    begin

        update db_sys.index_info_changeLog set is_current = 0 where indexName in (select indexName from inserted) and is_current = 1

        insert into db_sys.index_info_changeLog (indexName, row_version, is_current, tableName, projectID, script, info, createdBy, createdDate, updatedBy, updatedDate, deletedBy, deletedDate, errorBlock)
        select
            indexName, isnull((select max(row_version) from db_sys.index_info_changeLog cl where cl.indexName = i.indexName)+1,0), 1, tableName, projectID, script, info, createdBy, createdDate, updatedBy, updatedDate, deletedBy, deletedDate, errorBlock
        from
            inserted i

    end

end
GO
