CREATE TABLE [db_sys].[index_optimization] (
    [object_id]                    INT           NOT NULL,
    [index_id]                     INT           NOT NULL,
    [instance]                     INT           NOT NULL,
    [_rebuild]                     BIT           NOT NULL,
    [_reorganize]                  BIT           NOT NULL,
    [tsUTC]                        DATETIME2 (1) NOT NULL,
    [auditLog_ID]                  INT           NULL,
    [avg_fragmentation_in_percent] FLOAT (53)    NOT NULL
);
GO

ALTER TABLE [db_sys].[index_optimization]
    ADD CONSTRAINT [DF__index_optimization___reorganize] DEFAULT ((0)) FOR [_reorganize];
GO

ALTER TABLE [db_sys].[index_optimization]
    ADD CONSTRAINT [DF__index_optimization__tsUTC] DEFAULT (sysdatetime()) FOR [tsUTC];
GO

ALTER TABLE [db_sys].[index_optimization]
    ADD CONSTRAINT [DF__index_optimization___rebuild] DEFAULT ((0)) FOR [_rebuild];
GO

ALTER TABLE [db_sys].[index_optimization]
    ADD CONSTRAINT [DF__index_optimization__instance] DEFAULT ((0)) FOR [instance];
GO

ALTER TABLE [db_sys].[index_optimization]
    ADD CONSTRAINT [PK__index_optimization] PRIMARY KEY CLUSTERED ([object_id] ASC, [index_id] ASC, [instance] ASC);
GO

ALTER TABLE [db_sys].[index_optimization]
    ADD CONSTRAINT [CK__index_optimization___rebuild__reorganize] CHECK ([_rebuild]=(1) AND [_reorganize]=(0) OR [_rebuild]=(0) AND [_reorganize]=(1));
GO
