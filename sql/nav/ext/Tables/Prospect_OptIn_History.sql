CREATE TABLE [ext].[Prospect_OptIn_History] (
    [cus]            NVARCHAR (20) NOT NULL,
    [_start_date]    DATE          NOT NULL,
    [_end_date]      DATE          NULL,
    [email_optin]    BIT           NOT NULL,
    [addedTSUTC]     DATETIME2 (0) NOT NULL,
    [updatedTSUTC]   DATETIME2 (0) NULL,
    [opt_source_key] INT           NOT NULL
);
GO

ALTER TABLE [ext].[Prospect_OptIn_History]
    ADD CONSTRAINT [DF__Prospect_OptIn_History__email_optin] DEFAULT ((0)) FOR [email_optin];
GO

ALTER TABLE [ext].[Prospect_OptIn_History]
    ADD CONSTRAINT [DF__Prospect_OptIn_History__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO

ALTER TABLE [ext].[Prospect_OptIn_History]
    ADD CONSTRAINT [PK__Prospect_OptIn_History] PRIMARY KEY CLUSTERED ([cus] ASC, [_start_date] ASC);
GO
