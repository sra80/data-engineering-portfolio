CREATE TABLE [ext].[Platform] (
    [ID]         INT           IDENTITY (0, 1) NOT NULL,
    [Platform]   NVARCHAR (32) NOT NULL,
    [Country]    NVARCHAR (2)  NOT NULL,
    [AddedTSUTC] DATETIME2 (0) NOT NULL,
    [Group_ID]   INT           NULL
);
GO

ALTER TABLE [ext].[Platform]
    ADD CONSTRAINT [FK__Platform__Group_ID] FOREIGN KEY ([Group_ID]) REFERENCES [ext].[Platform_Grouping] ([ID]);
GO

ALTER TABLE [ext].[Platform]
    ADD CONSTRAINT [DF__Platform__AddedTSUTC] DEFAULT (getutcdate()) FOR [AddedTSUTC];
GO

ALTER TABLE [ext].[Platform]
    ADD CONSTRAINT [PK__Platform] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__FE7]
    ON [ext].[Platform]([Platform] ASC, [Country] ASC);
GO
