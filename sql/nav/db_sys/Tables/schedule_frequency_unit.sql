CREATE TABLE [db_sys].[schedule_frequency_unit] (
    [id]                INT           NOT NULL,
    [frequency_unit]    NVARCHAR (16) NOT NULL,
    [frequency_ratio]   FLOAT (53)    NOT NULL,
    [minute_conversion] INT           NOT NULL,
    [granularity]       INT           NOT NULL
);
GO

ALTER TABLE [db_sys].[schedule_frequency_unit]
    ADD CONSTRAINT [PK__schedule_frequency_unit] PRIMARY KEY CLUSTERED ([id] ASC);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__7A5]
    ON [db_sys].[schedule_frequency_unit]([frequency_unit] ASC);
GO