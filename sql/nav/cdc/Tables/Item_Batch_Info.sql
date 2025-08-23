DROP TABLE IF EXISTS [cdc].[Item_Batch_Info]
GO

CREATE TABLE [cdc].[Item_Batch_Info] (
    [cdc_instance]                 uniqueidentifier NOT NULL,
    [cdc_addTS]                    DATETIME2(3)     NOT NULL,
    [id]                           INT              NOT NULL,
    [unit_cost]                    MONEY            NULL
);
GO

ALTER TABLE [cdc].[Item_Batch_Info]
    ADD CONSTRAINT [PK__Item_Batch_Info] PRIMARY KEY CLUSTERED 
    (
        [cdc_instance],
        [id]
    );
GO

ALTER TABLE [cdc].[Item_Batch_Info]
    ADD CONSTRAINT [DF__Item_Batch_Info__cdc_addTS] DEFAULT getutcdate() for cdc_addTS;
GO

create index IX__561 on [cdc].[Item_Batch_Info] (cdc_instance)
go