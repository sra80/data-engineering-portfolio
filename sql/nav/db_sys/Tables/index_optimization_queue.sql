CREATE TABLE [db_sys].[index_optimization_queue] (
    [ID]         INT           IDENTITY (1, 1) NOT NULL,
    [object_id]  INT           NOT NULL,
    [index_id]   INT           NOT NULL,
    [addedTSUTC] DATETIME2 (1) NOT NULL
);
GO

ALTER TABLE [db_sys].[index_optimization_queue]
    ADD CONSTRAINT [DF__index_optimization_queue__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO

ALTER TABLE [db_sys].[index_optimization_queue]
    ADD CONSTRAINT [PK__index_optimization_queue] PRIMARY KEY CLUSTERED ([object_id] ASC, [index_id] ASC);
GO
