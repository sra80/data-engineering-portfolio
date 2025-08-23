CREATE TABLE [ext].[Prospect_Convert] (
    [cus]                           NVARCHAR (20) NOT NULL,
    [_start_date]                   DATE          NOT NULL,
    [_end_date]                     DATE          NOT NULL,
    [addedTSUTC]                    DATETIME2 (0) NOT NULL,
    [update_Prospect_OptIn_History] BIT           NOT NULL
);
GO

ALTER TABLE [ext].[Prospect_Convert]
    ADD CONSTRAINT [PK__Prospect_Convert] PRIMARY KEY CLUSTERED ([cus] ASC);
GO

ALTER TABLE [ext].[Prospect_Convert]
    ADD CONSTRAINT [DF__Prospect_Convert__update_Prospect_OptIn_History] DEFAULT ((1)) FOR [update_Prospect_OptIn_History];
GO

ALTER TABLE [ext].[Prospect_Convert]
    ADD CONSTRAINT [DF__Prospect_Convert__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO
