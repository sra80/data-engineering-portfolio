create table cdc.Subscriptions_Line
    (
        [cdc_instance]                 uniqueidentifier NOT NULL,
        [cdc_is_inserted]              bit              NOT NULL,
        [cdc_is_deleted]               bit              NOT NULL,
        [cdc_addTS]                    DATETIME2(3)     NOT NULL,
        [company_id]                   INT              NOT NULL,
        [Subscription No_]             NVARCHAR (20)    NOT NULL,
        [Line No_]                     INT              NOT NULL,
        [Item No_]                     NVARCHAR (20)    NOT NULL,
        [Customer No_]                 NVARCHAR (20)    NOT NULL,
        [Status]                       INT              NOT NULL,
        [Starting Date]                DATETIME         NULL,
        [Ending Date]                  DATETIME         NULL,
        [Next Delivery Date]           DATETIME         NULL,
        [Frequency (Date Formula)]     VARCHAR (32)     NOT NULL,
        [Frequency (No_ of Days)]      INT              NOT NULL,
        [Quantity]                     DECIMAL (38, 20) NOT NULL,
        [Price]                        DECIMAL (38, 20) NOT NULL,
        [Unit of Measure Code]         NVARCHAR (10)    NOT NULL,
        [Quantity (Base)]              DECIMAL (38, 20) NOT NULL,
        [Qty_ per Unit of Measure]     DECIMAL (38, 20) NOT NULL,
        [Last S&S Order Creation Date] DATETIME         NULL,
        [Last Modified DateTime]       DATETIME         NULL,
        [Last Modified By]             NVARCHAR (50)    NOT NULL,
        [Last Notification Email Date] DATETIME         NULL,
        [Standard Price]               DECIMAL (38, 20) NOT NULL,
        [Subscription Signup Price]    DECIMAL (38, 20) NOT NULL
    )

ALTER TABLE [cdc].[Subscriptions_Line] ADD  CONSTRAINT [PK__Subscriptions_Line] PRIMARY KEY CLUSTERED 
(
	[cdc_instance] ASC,
    [cdc_is_inserted],
    [cdc_is_deleted] ASC,
    [company_id] ASC,
    [Subscription No_] ASC,
    [Line No_] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

ALTER TABLE [cdc].[Subscriptions_Line]
    ADD CONSTRAINT [DF__Subscriptions_Line__cdc_is_inserted] DEFAULT 0 for cdc_is_inserted;
GO

ALTER TABLE [cdc].[Subscriptions_Line]
    ADD CONSTRAINT [DF__Subscriptions_Line__cdc_is_deleted] DEFAULT 0 for cdc_is_deleted;
GO

ALTER TABLE [cdc].[Subscriptions_Line]
    ADD CONSTRAINT [DF__Subscriptions_Line__cdc_addTS] DEFAULT getutcdate() for cdc_addTS;
GO

create index IX__64B on cdc.Subscriptions_Line ([Last Modified By])
go