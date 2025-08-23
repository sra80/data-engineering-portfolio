CREATE TABLE [ext].[Customer_Status_History_v2] (
    [customer_id] INT           NOT NULL,
    [date_start]  DATE          NOT NULL,
    [date_end]    DATE          NULL,
    [status_id]   INT           NOT NULL,
    [last_order]  DATE          NULL,
    [addTS]       DATETIME2 (3) NOT NULL,
    [revTS]       DATETIME2 (3) NOT NULL
);
GO

ALTER TABLE [ext].[Customer_Status_History_v2]
    ADD CONSTRAINT [CK__Customer_Status_History_v2__date_start__date_end] CHECK ([date_start]<=[date_end] OR [date_end] IS NULL);
GO

ALTER TABLE [ext].[Customer_Status_History_v2]
    ADD CONSTRAINT [DF__Customer_Status_History_v2__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO

ALTER TABLE [ext].[Customer_Status_History_v2]
    ADD CONSTRAINT [DF__Customer_Status_History_v2__revTS] DEFAULT (sysdatetime()) FOR [revTS];
GO

ALTER TABLE [ext].[Customer_Status_History_v2]
    ADD CONSTRAINT [FK__Customer_Status_History_v2__status_id] FOREIGN KEY ([status_id]) REFERENCES [ext].[Customer_Status] ([ID]);
GO

ALTER TABLE [ext].[Customer_Status_History_v2]
    ADD CONSTRAINT [FK__Customer_Status_History_v2__customer_id] FOREIGN KEY ([customer_id]) REFERENCES [hs_identity_link].[Customer] ([ID]);
GO

ALTER TABLE [ext].[Customer_Status_History_v2]
    ADD CONSTRAINT [PK__Customer_Status_History_v2] PRIMARY KEY CLUSTERED ([customer_id] ASC, [date_start] ASC);
GO
