CREATE TABLE [db_sys].[procedure_dependents] (
    [source]                 NVARCHAR (64) NOT NULL,
    [source_is_partition]    BIT           NOT NULL,
    [dependant]              NVARCHAR (64) NOT NULL,
    [dependant_is_partition] BIT           NOT NULL,
    [process]                BIT           NOT NULL
);
GO

ALTER TABLE [db_sys].[procedure_dependents]
    ADD CONSTRAINT [DF__procedure_dependents__process] DEFAULT ((0)) FOR [process];
GO

ALTER TABLE [db_sys].[procedure_dependents]
    ADD CONSTRAINT [DF__procedure_dependents__dependant_is_partition] DEFAULT ((0)) FOR [dependant_is_partition];
GO

ALTER TABLE [db_sys].[procedure_dependents]
    ADD CONSTRAINT [DF__procedure_dependents__source_is_partition] DEFAULT ((0)) FOR [source_is_partition];
GO
