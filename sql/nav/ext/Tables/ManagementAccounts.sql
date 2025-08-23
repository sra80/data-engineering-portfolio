CREATE TABLE [ext].[ManagementAccounts] (
    [keyAccountCode]      NVARCHAR (10) NOT NULL,
    [Management Heading]  NVARCHAR (50) NOT NULL,
    [Management Category] NVARCHAR (50) NOT NULL,
    [Heading Sort]        INT           NOT NULL,
    [Category Sort]       INT           NOT NULL,
    [main]                BIT           NOT NULL,
    [invert]              BIT           NOT NULL,
    [ma]                  BIT           NOT NULL,
    [Channel Category]    NVARCHAR (50) NULL,
    [Channel Sort]        INT           NOT NULL
);
GO

ALTER TABLE [ext].[ManagementAccounts]
    ADD CONSTRAINT [DF__ManagementAccounts__ma] DEFAULT ((1)) FOR [ma];
GO

ALTER TABLE [ext].[ManagementAccounts]
    ADD CONSTRAINT [DF__ManagementAccounts__main] DEFAULT ((0)) FOR [main];
GO

ALTER TABLE [ext].[ManagementAccounts]
    ADD CONSTRAINT [DF__ManagementAccounts__invert] DEFAULT ((0)) FOR [invert];
GO

ALTER TABLE [ext].[ManagementAccounts]
    ADD CONSTRAINT [PK__ManagementAccounts] PRIMARY KEY CLUSTERED ([keyAccountCode] ASC, [Management Heading] ASC);
GO
