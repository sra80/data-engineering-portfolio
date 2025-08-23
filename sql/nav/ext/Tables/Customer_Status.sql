CREATE TABLE [ext].[Customer_Status] (
    [ID]              INT           IDENTITY (1, 1) NOT NULL,
    [Customer_Status] NVARCHAR (32) NULL,
    [is_active]       BIT           NOT NULL,
    [is_deleted]      BIT           NOT NULL,
    [is_intro_status] BIT           NOT NULL,
    [is_customer]     BIT           NOT NULL
);
GO

ALTER TABLE [ext].[Customer_Status]
    ADD CONSTRAINT [PK__Customer_Status] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

ALTER TABLE [ext].[Customer_Status]
    ADD CONSTRAINT [DF__Customer_Status__is_intro_status] DEFAULT ((0)) FOR [is_intro_status];
GO

ALTER TABLE [ext].[Customer_Status]
    ADD CONSTRAINT [DF__Customer_Status__is_active] DEFAULT ((0)) FOR [is_active];
GO

ALTER TABLE [ext].[Customer_Status]
    ADD CONSTRAINT [DF__Customer_Status__is_customer] DEFAULT ((0)) FOR [is_customer];
GO

ALTER TABLE [ext].[Customer_Status]
    ADD CONSTRAINT [DF__Customer_Status__is_deleted] DEFAULT ((0)) FOR [is_deleted];
GO
