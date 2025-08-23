SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [cdc].[Sales_Price_Holding_Table](
    [cdc_instance]                 uniqueidentifier NOT NULL,
    [cdc_is_inserted]              bit              NOT NULL,
    [cdc_is_deleted]               bit              NOT NULL,
    [cdc_addTS]                    DATETIME2(3)     NOT NULL,
    [company_id]                   INT              NOT NULL,
	[Entry No_] [int] NOT NULL,
	[Status] [int] NOT NULL,
	[Ignored] [tinyint] NOT NULL,
	[Error Msg] [nvarchar](250) NULL,
	[Item No_] [nvarchar](20) NOT NULL,
	[Sales Code] [nvarchar](20) NOT NULL,
	[Currency Code] [nvarchar](10) NULL,
	[Starting Date] [datetime] NOT NULL,
	[Unit Price] [decimal](38, 20) NOT NULL,
	[Price Includes VAT] [tinyint] NOT NULL,
	[Allow Invoice Disc_] [tinyint] NOT NULL,
	[Sales Type] [int] NOT NULL,
	[Minimum Quantity] [decimal](38, 20) NOT NULL,
	[Ending Date] [datetime] NOT NULL,
	[Unit of Measure Code] [nvarchar](10) NULL,
	[Variant Code] [nvarchar](10) NOT NULL,
	[Allow Line Disc_] [tinyint] NOT NULL,
	[External ID] uniqueidentifier NULL,
	[Price Approved] [tinyint] NOT NULL,
	[Created Date_Time] [datetime] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [cdc].[Sales_Price_Holding_Table] ADD  CONSTRAINT [PK__Sales_Price_Holding_Table] PRIMARY KEY CLUSTERED 
(
	[cdc_instance] ASC,
    [cdc_is_inserted],
    [cdc_is_deleted] ASC,
    [company_id] ASC,
    [Entry No_] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

ALTER TABLE [cdc].[Sales_Price_Holding_Table]
    ADD CONSTRAINT [DF__Sales_Price_Holding_Table__cdc_is_inserted] DEFAULT 0 for cdc_is_inserted;
GO

ALTER TABLE [cdc].[Sales_Price_Holding_Table]
    ADD CONSTRAINT [DF__Sales_Price_Holding_Table__cdc_is_deleted] DEFAULT 0 for cdc_is_deleted;
GO

ALTER TABLE [cdc].[Sales_Price_Holding_Table]
    ADD CONSTRAINT [DF__Sales_Price_Holding_Table__cdc_addTS] DEFAULT getutcdate() for cdc_addTS;
GO