CREATE TABLE [ext].[Prospect] (
    [cus]                           NVARCHAR (20) NOT NULL,
    [AddedTSUTC]                    DATETIME2 (0) NOT NULL,
    [UpdatedTSUTC]                  DATETIME2 (0) NULL,
    [email_valid]                   BIT           NOT NULL,
    [optcheck]                      BIT           NULL,
    [email_optin]                   BIT           NOT NULL,
    [post_optin]                    BIT           NOT NULL,
    [phone_optin]                   BIT           NOT NULL,
    [email_ts]                      DATETIME2 (0) NULL,
    [post_ts]                       DATETIME2 (0) NULL,
    [phone_ts]                      DATETIME2 (0) NULL,
    [update_Prospect_OptIn_History] BIT           NOT NULL,
    [ID]                            INT           NOT NULL
);
GO

ALTER TABLE [ext].[Prospect]
    ADD CONSTRAINT [DF__Prospect__ID] DEFAULT (NEXT VALUE FOR [ext].[sq_Customer]) FOR [ID];
GO

ALTER TABLE [ext].[Prospect]
    ADD CONSTRAINT [DF__Prospect__email_valid] DEFAULT ((0)) FOR [email_valid];
GO

ALTER TABLE [ext].[Prospect]
    ADD CONSTRAINT [DF__Prospect__phone_optin] DEFAULT ((0)) FOR [phone_optin];
GO

ALTER TABLE [ext].[Prospect]
    ADD CONSTRAINT [DF__Prospect__AddedTSUTC] DEFAULT (getutcdate()) FOR [AddedTSUTC];
GO

ALTER TABLE [ext].[Prospect]
    ADD CONSTRAINT [DF__Prospect__update_Prospect_OptIn_History] DEFAULT ((1)) FOR [update_Prospect_OptIn_History];
GO

ALTER TABLE [ext].[Prospect]
    ADD CONSTRAINT [DF__Prospect__optcheck] DEFAULT ((0)) FOR [optcheck];
GO

ALTER TABLE [ext].[Prospect]
    ADD CONSTRAINT [DF__Prospect__email_optin] DEFAULT ((0)) FOR [email_optin];
GO

ALTER TABLE [ext].[Prospect]
    ADD CONSTRAINT [DF__Prospect__post_optin] DEFAULT ((0)) FOR [post_optin];
GO

ALTER TABLE [ext].[Prospect]
    ADD CONSTRAINT [PK__Prospect] PRIMARY KEY CLUSTERED ([cus] ASC);
GO
