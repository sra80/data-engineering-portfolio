CREATE TABLE [ext].[Customer_Balance_Tracker] (
    [Customer_ID] INT           NOT NULL,
    [row_version] INT           NOT NULL,
    [is_current]  BIT           NOT NULL,
    [balance]     MONEY         NOT NULL,
    [addedTSUTC]  DATETIME2 (0) NULL
);
GO

ALTER TABLE [ext].[Customer_Balance_Tracker]
    ADD CONSTRAINT [PK__Customer_Balance_Tracker] PRIMARY KEY CLUSTERED ([Customer_ID] ASC, [row_version] ASC);
GO

ALTER TABLE [ext].[Customer_Balance_Tracker]
    ADD CONSTRAINT [DF__Customer_Balance_Tracker__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO
