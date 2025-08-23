CREATE TABLE [ext].[Item] (
    [ID]                 INT           IDENTITY (1, 1) NOT NULL,
    [company_id]         INT           NOT NULL,
    [No_]                NVARCHAR (40) NOT NULL,
    [firstOrder]         DATE          NULL,
    [firstBMSync]        DATETIME2 (0) NULL,
    [lastBMSync]         DATETIME2 (0) NULL,
    [outstandingBMSync]  BIT           NOT NULL,
    [firstBMSyncRequest] DATETIME2 (0) NULL,
    [lastBMSyncRequest]  DATETIME2 (0) NULL,
    [countBMSyncRequest] INT           NOT NULL,
    [bm_checksum]        BIGINT        NULL,
    [lastOrder]          DATE          NULL,
    [addedTSUTC]         DATETIME2 (1) NOT NULL,
    [last_oos_plr]       DATETIME2 (3) NULL,
    [ringfenced_until]   DATETIME2 (3) NULL,
    [avg_price_single]   MONEY         NULL,
    [avg_price_repeat]   MONEY         NULL,
    [avg_price_update]   DATETIME2 (3) NULL,
    hex_color            NVARCHAR(7)  NULL
);
GO

GRANT UPDATE
    ON [ext].[Item] ([firstBMSync]) TO [brandmaker_integration]
    AS [dbo];
GO

GRANT UPDATE
    ON [ext].[Item] ([lastBMSync]) TO [brandmaker_integration]
    AS [dbo];
GO

GRANT UPDATE
    ON [ext].[Item] ([outstandingBMSync]) TO [brandmaker_integration]
    AS [dbo];
GO

ALTER TABLE [ext].[Item]
    ADD CONSTRAINT [FK__Item__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

ALTER TABLE [ext].[Item]
    ADD CONSTRAINT [DF__outstandingBMSync__outstandingBMSync] DEFAULT ((0)) FOR [outstandingBMSync];
GO

ALTER TABLE [ext].[Item]
    ADD CONSTRAINT [DF__Item__countBMSyncRequest] DEFAULT ((0)) FOR [countBMSyncRequest];
GO

ALTER TABLE [ext].[Item]
    ADD CONSTRAINT [DF__Item__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO

ALTER TABLE [ext].[Item]
    ADD CONSTRAINT [PK__Item] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__2AB]
    ON [ext].[Item]([company_id] ASC, [No_] ASC);
GO

CREATE NONCLUSTERED INDEX IX__F52 ON [ext].[Item] ([No_])
GO