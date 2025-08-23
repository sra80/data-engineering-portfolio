drop table if exists  [cdc].[Subscription_Date_Move2]
GO

create table [cdc].[Subscription_Date_Move2]
    (
        [cdc_instance]                 uniqueidentifier NOT NULL,
        [cdc_is_inserted]              bit              NOT NULL,
        [cdc_is_deleted]               bit              NOT NULL,
        [cdc_addTS]                    DATETIME2(3)     NOT NULL,
        [company_id]                   INT              NOT NULL,
        [Move From Date]               DATETIME2(3)     NOT NULL,
        [Move To Date]                 DATETIME2(3)     NOT NULL,
    )
GO

ALTER TABLE [cdc].[Subscription_Date_Move2]
    ADD CONSTRAINT [PK__Subscription_Date_Move2] PRIMARY KEY CLUSTERED 
    (
        [cdc_instance],
        [cdc_is_inserted],
        [cdc_is_deleted],
        [company_id],
        [Move From Date]
    );
GO

ALTER TABLE [cdc].[Subscription_Date_Move2]
    ADD CONSTRAINT [DF__Subscription_Date_Move2__cdc_is_inserted] DEFAULT 0 for cdc_is_inserted;
GO

ALTER TABLE [cdc].[Subscription_Date_Move2]
    ADD CONSTRAINT [DF__Subscription_Date_Move2__cdc_is_deleted] DEFAULT 0 for cdc_is_deleted;
GO

ALTER TABLE [cdc].[Subscription_Date_Move2]
    ADD CONSTRAINT [DF__Subscription_Date_Move2__cdc_addTS] DEFAULT getutcdate() for cdc_addTS;
GO