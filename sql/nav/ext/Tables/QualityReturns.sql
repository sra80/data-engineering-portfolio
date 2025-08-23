
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ext].[QualityReturns](
	[itemID] [int] NULL,
    [batchID] [int] NULL,
	[Company] [nvarchar](32) NOT NULL,
	[Return Document] [nvarchar](20) NOT NULL,
	[Line No] [int] NOT NULL,
	[keyDate] [int] NOT NULL,
	[Range Code] [nvarchar](10) NOT NULL,
	[Customer No] [nvarchar](20) NOT NULL,
	[Item No] [nvarchar](20) NOT NULL,
	[Item Description] [nvarchar](50) NOT NULL,
	[Quantity] [int] NOT NULL,
	[Return Type] [nvarchar](20) NOT NULL,
	[keyQualityType] [int] NOT NULL,
	[Return Reason Code] [nvarchar](10) NOT NULL,
	[Return Reason Description] [nvarchar](50) NOT NULL,
	[Comment] [nvarchar](80) NULL,
	[Sales Order Reference] [nvarchar](20) NOT NULL,
	[Lot No] [nvarchar](20) NOT NULL,
	[Expiry Date] [date] NULL,
	[Date of Original Order] [date] NULL,
	[Return Created By] [nvarchar](50) NOT NULL,
	[company_id] [int] NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
ALTER TABLE [ext].[QualityReturns] ADD  CONSTRAINT [PK__QualityReturns] PRIMARY KEY CLUSTERED 
(
	[Company] ASC,
	[Return Document] ASC,
	[Line No] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO