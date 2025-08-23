CREATE TABLE [forecast_feed].[stock_history] (
    [is_current]   BIT           NOT NULL,
    [key_location] INT           NOT NULL,
    [key_batch]    INT           NOT NULL,
    [closing_date] DATE          NOT NULL,
    [units]        FLOAT (53)    NULL,
    [addedTSUTC]   DATETIME2 (1) NOT NULL
);
GO

ALTER TABLE [forecast_feed].[stock_history]
    ADD CONSTRAINT [DF__stock_history__is_current] DEFAULT ((0)) FOR [is_current];
GO

ALTER TABLE [forecast_feed].[stock_history]
    ADD CONSTRAINT [DF__stock_history__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO

ALTER TABLE [forecast_feed].[stock_history]
    ADD CONSTRAINT [PK__stock_history] PRIMARY KEY CLUSTERED ([is_current] ASC, [key_location] ASC, [key_batch] ASC, [closing_date] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__C80]
    ON [forecast_feed].[stock_history]([is_current] ASC, [closing_date] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__A2A]
    ON [forecast_feed].[stock_history]([closing_date] ASC);
GO
