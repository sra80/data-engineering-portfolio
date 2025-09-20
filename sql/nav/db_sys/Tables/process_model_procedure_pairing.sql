CREATE TABLE [db_sys].[process_model_procedure_pairing] (
    [model_name]    NVARCHAR (32) NOT NULL,
    [procedureName] NVARCHAR (128) NOT NULL
);
GO

ALTER TABLE [db_sys].[process_model_procedure_pairing]
    ADD CONSTRAINT [PK__process_model_procedure_pairing] PRIMARY KEY CLUSTERED ([model_name] ASC, [procedureName] ASC);
GO