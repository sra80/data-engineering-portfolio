CREATE TABLE [stock].[location_overide] (
    [_input]  INT NOT NULL,
    [_output] INT NULL
);
GO

ALTER TABLE [stock].[location_overide]
    ADD CONSTRAINT [PK__location_overide] PRIMARY KEY CLUSTERED ([_input] ASC);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__9C9]
    ON [stock].[location_overide]([_output] ASC);
GO
