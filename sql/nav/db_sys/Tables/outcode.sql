CREATE TABLE [db_sys].[outcode] (
    [id]        INT           IDENTITY (-1, 1) NOT NULL,
    [outcode]   NVARCHAR (4)  NOT NULL,
    [eastings]  INT           NOT NULL,
    [northings] INT           NOT NULL,
    [latitude]  FLOAT (53)    NOT NULL,
    [longitude] FLOAT (53)    NOT NULL,
    [town]      NVARCHAR (64) NULL,
    [region]    NVARCHAR (32) NOT NULL,
    [country]   NVARCHAR (2)  NOT NULL
);
GO

ALTER TABLE [db_sys].[outcode]
    ADD CONSTRAINT [PK__outcodes_uk] PRIMARY KEY CLUSTERED ([id] ASC);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__F4F]
    ON [db_sys].[outcode]([country] ASC,[outcode] ASC);
GO

CREATE NONCLUSTERED INDEX IX__68F
ON [db_sys].[outcode] ([outcode])
INCLUDE ([country])
GO