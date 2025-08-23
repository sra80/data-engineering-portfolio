DROP TABLE IF EXISTS [cdc].[Sales_Price]
GO

CREATE TABLE [cdc].[Sales_Price] (
    [cdc_instance]                 uniqueidentifier NOT NULL,
    [cdc_is_inserted]              bit              NOT NULL,
    [cdc_is_deleted]               bit              NOT NULL,
    [cdc_addTS]                    DATETIME2(3)     NOT NULL,
    [company_id]                   INT              NOT NULL,
    [Item No_]                     NVARCHAR (20)    NOT NULL,
    [Sales Type]                   INT              NOT NULL,
    [Sales Code]                   NVARCHAR (20)    NOT NULL,
    [Starting Date]                DATETIME         NOT NULL,
    [Currency Code]                NVARCHAR (10)    NOT NULL,
    [Variant Code]                 NVARCHAR (10)    NOT NULL,
    [Unit of Measure Code]         NVARCHAR (10)    NOT NULL,
    [Minimum Quantity]             DECIMAL (38, 20) NOT NULL,
    [Unit Price]                   DECIMAL (38, 20) NOT NULL,
    [Price Includes VAT]           TINYINT          NOT NULL,
    [Allow Invoice Disc_]          TINYINT          NOT NULL,
    [VAT Bus_ Posting Gr_ (Price)] NVARCHAR (10)    NOT NULL,
    [Ending Date]                  DATETIME         NOT NULL,
    [Allow Line Disc_]             TINYINT          NOT NULL,
    [Force 0 Price]                BIT              NOT NULL,
    [External ID]                  uniqueidentifier NULL
);
GO

ALTER TABLE [cdc].[Sales_Price]
    ADD CONSTRAINT [PK__Sales_Price] PRIMARY KEY CLUSTERED 
    (
        [cdc_instance],
        [cdc_is_inserted],
        [cdc_is_deleted],
        [company_id],
        [Item No_],
        [Sales Type],
        [Sales Code],
        [Starting Date],
        [Currency Code],
        [Variant Code],
        [Unit of Measure Code],
        [Minimum Quantity]);
GO

ALTER TABLE [cdc].[Sales_Price]
    ADD CONSTRAINT [DF__Sales_Price__cdc_is_inserted] DEFAULT 0 for cdc_is_inserted;
GO

ALTER TABLE [cdc].[Sales_Price]
    ADD CONSTRAINT [DF__Sales_Price__cdc_is_deleted] DEFAULT 0 for cdc_is_deleted;
GO

ALTER TABLE [cdc].[Sales_Price]
    ADD CONSTRAINT [DF__Sales_Price__cdc_addTS] DEFAULT getutcdate() for cdc_addTS;
GO

CREATE INDEX [IX__2B2] on [cdc].[Sales_Price]
    (

        [company_id],
        [Item No_],
        [Sales Type],
        [Sales Code],
        [Starting Date],
        [Currency Code],
        [Variant Code],
        [Unit of Measure Code],
        [Minimum Quantity]
    )