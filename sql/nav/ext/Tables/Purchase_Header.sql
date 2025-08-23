CREATE TABLE [ext].[Purchase_Header] (
    [ID]            INT           IDENTITY (0, 1) NOT NULL,
    [company_id]    INT           NOT NULL,
    [Document Type] INT           NOT NULL,
    [No_]           NVARCHAR (20) NOT NULL,
    [addedTSUTC]    DATETIME2 (3) NOT NULL,
    [queue_oos_plr] BIT           NOT NULL
);
GO

ALTER TABLE [ext].[Purchase_Header]
    ADD CONSTRAINT [FK__Purchase_Header__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

ALTER TABLE [ext].[Purchase_Header]
    ADD CONSTRAINT [DF__Purchase_Header__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO

ALTER TABLE [ext].[Purchase_Header]
    ADD CONSTRAINT [DF__Purchase_Header__queue_oos_plr] DEFAULT ((0)) FOR [queue_oos_plr];
GO

ALTER TABLE [ext].[Purchase_Header]
    ADD CONSTRAINT [PK__Purchase_Header] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__C00]
    ON [ext].[Purchase_Header]([company_id] ASC, [Document Type] ASC, [No_] ASC);
GO
