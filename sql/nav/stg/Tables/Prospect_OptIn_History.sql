CREATE TABLE [stg].[Prospect_OptIn_History] (
    [cus]         NVARCHAR (20)  NULL,
    [_start_date] DATE           NULL,
    [_end_date]   DATE           NULL,
    [email_optin] BIT            NULL,
    [opt_source]  NVARCHAR (255) NULL
);
GO
