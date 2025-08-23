CREATE TABLE [ext].[Customer] (
    [cus]                NVARCHAR (20) NOT NULL,
    [first_platformID]   INT           NOT NULL,
    [first_channel_code] NVARCHAR (10) NOT NULL,
    [first_order_date]   DATE          NOT NULL,
    [AddedTSUTC]         DATETIME2 (0) NOT NULL,
    [UpdatedTSUTC]       DATETIME2 (0) NULL,
    [optcheck]           BIT           NULL,
    [email_optin]        BIT           NOT NULL,
    [post_optin]         BIT           NOT NULL,
    [phone_optin]        BIT           NOT NULL,
    [email_ts]           DATETIME2 (0) NULL,
    [post_ts]            DATETIME2 (0) NULL,
    [phone_ts]           DATETIME2 (0) NULL,
    [email_valid]        BIT           NOT NULL,
    [ID]                 INT           NOT NULL,
    [balance]            MONEY         NOT NULL,
    [company_id]         INT           NOT NULL,
    streak_last_update   DATETIME2 (0) NULL,
    streak_first_order   DATE          NULL,
    streak_last_order    DATE          NULL

);
GO

ALTER TABLE [ext].[Customer]
    ADD CONSTRAINT [DF__Customer__email_valid] DEFAULT ((0)) FOR [email_valid];
GO

ALTER TABLE [ext].[Customer]
    ADD CONSTRAINT [DF__Customer__ID] DEFAULT (NEXT VALUE FOR [ext].[sq_Customer]) FOR [ID];
GO

ALTER TABLE [ext].[Customer]
    ADD CONSTRAINT [DF__Customer__balance] DEFAULT ((0)) FOR [balance];
GO

ALTER TABLE [ext].[Customer]
    ADD CONSTRAINT [DF__Customer__email_optin] DEFAULT ((0)) FOR [email_optin];
GO

ALTER TABLE [ext].[Customer]
    ADD CONSTRAINT [DF__Customer__AddedTSUTC] DEFAULT (getutcdate()) FOR [AddedTSUTC];
GO

ALTER TABLE [ext].[Customer]
    ADD CONSTRAINT [DF__Customer__company_id] DEFAULT ((1)) FOR [company_id];
GO

ALTER TABLE [ext].[Customer]
    ADD CONSTRAINT [DF__Customer__optcheck] DEFAULT ((0)) FOR [optcheck];
GO

ALTER TABLE [ext].[Customer]
    ADD CONSTRAINT [DF__Customer__phone_optin] DEFAULT ((0)) FOR [phone_optin];
GO

ALTER TABLE [ext].[Customer]
    ADD CONSTRAINT [DF__Customer__post_optin] DEFAULT ((0)) FOR [post_optin];
GO

ALTER TABLE [ext].[Customer]
    ADD CONSTRAINT [PK__Customer] PRIMARY KEY CLUSTERED ([company_id] ASC, [cus] ASC);
GO

ALTER TABLE [ext].[Customer]
    ADD CONSTRAINT [FK__Customer__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO


CREATE trigger ext.Customer_update_balance on ext.Customer

for update

as

begin

set nocount on

if update (balance)

    begin

        update ext.Customer_Balance_Tracker set is_current = 0 where Customer_ID in (select ID from inserted) and is_current = 1

        insert into ext.Customer_Balance_Tracker (Customer_ID, row_version, is_current, balance)
        select
            i.ID,
            (select isnull(max(row_version),-1) from ext.Customer_Balance_Tracker cbt where cbt.Customer_ID = i.ID) + 1,
            1,
            i.balance
        from
            inserted i

    end

end
GO

CREATE NONCLUSTERED INDEX [IX__03E]
    ON [ext].[Customer]([cus] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__736]
    ON [ext].[Customer]([cus] ASC, [balance] ASC);
GO

create index IX__DEB on [ext].[Customer] (streak_last_update)
go