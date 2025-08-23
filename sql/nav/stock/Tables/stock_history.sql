CREATE TABLE [stock].[stock_history] (
    [key_location] INT           NOT NULL,
    [key_batch]    INT           NOT NULL,
    [closing_date] DATE          NOT NULL,
    [units]        FLOAT (53)    NULL,
    [addedTSUTC]   DATETIME2 (1) NOT NULL
);
GO

ALTER TABLE [stock].[stock_history]
    ADD CONSTRAINT [PK__stock_history] PRIMARY KEY CLUSTERED ([key_location] ASC, [key_batch] ASC, [closing_date] ASC);
GO

ALTER TABLE [stock].[stock_history]
    ADD CONSTRAINT [DF__stock_history__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO

CREATE NONCLUSTERED INDEX [IX__FCC]
    ON [stock].[stock_history]([closing_date] ASC);
GO
