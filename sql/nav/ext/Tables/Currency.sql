CREATE TABLE [ext].[Currency] (
    [ID]         INT           IDENTITY (0, 1) NOT NULL,
    [code]       NVARCHAR (10) NOT NULL,
    [addedTSUTC] DATETIME2 (0) NOT NULL
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__285]
    ON [ext].[Currency]([code] ASC);
GO

ALTER TABLE [ext].[Currency]
    ADD CONSTRAINT [DF__Currency__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO

ALTER TABLE [ext].[Currency]
    ADD CONSTRAINT [PK__Currency] PRIMARY KEY CLUSTERED ([ID] ASC);
GO
