CREATE TABLE [ext].[On_Hold_Reason] (
    [ID]             INT           IDENTITY (0, 1) NOT NULL,
    [company_id]     INT           NOT NULL,
    [on_hold_reason] NVARCHAR (10) NOT NULL,
    [addedTSUTC]     DATETIME2 (0) NOT NULL
);
GO

ALTER TABLE [ext].[On_Hold_Reason]
    ADD CONSTRAINT [PK__On_Hold_Reason] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

ALTER TABLE [ext].[On_Hold_Reason]
    ADD CONSTRAINT [FK__On_Hold_Reason__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

ALTER TABLE [ext].[On_Hold_Reason]
    ADD CONSTRAINT [DF__On_Hold_Reason__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO
