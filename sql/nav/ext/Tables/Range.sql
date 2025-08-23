CREATE TABLE [ext].[Range] (
    [ID]              INT           IDENTITY (0, 1) NOT NULL,
    [company_id]      INT           NOT NULL,
    [range_code]      NVARCHAR (10) NOT NULL,
    [is_inc_yieldigo] bit           NOT NULL,
    [is_inc_anaplan]  bit           NOT NULL,
    [addedTS]         DATETIME2 (3) NOT NULL
);
GO

ALTER TABLE [ext].[Range]
    ADD CONSTRAINT [FK__Range__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__111]
    ON [ext].[Range]([company_id] ASC, [range_code] ASC);
GO

ALTER TABLE [ext].[Range]
    ADD CONSTRAINT [DF__Range__addedTS] DEFAULT (sysdatetime()) FOR [addedTS];
GO

ALTER TABLE [ext].[Range]
    ADD CONSTRAINT [DF__Range__is_inc_yieldigo] DEFAULT (1) FOR [is_inc_yieldigo];
GO

ALTER TABLE [ext].[Range]
    ADD CONSTRAINT [DF__Range__is_inc_anaplan] DEFAULT (1) FOR [is_inc_anaplan];
GO

ALTER TABLE [ext].[Range]
    ADD CONSTRAINT [PK__Range] PRIMARY KEY CLUSTERED ([ID] ASC);
GO