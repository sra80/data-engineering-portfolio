SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ext].[QualityReturnedProducts](
	[_itemID] [int] NOT NULL,
    [_batchID] [int] NOT NULL,
	[Return Year] [int] NOT NULL,
	[_keyQualityType] [int] NOT NULL,
	[Lot No] [nvarchar](20) NOT NULL,
	[Expiry Date] [date] NULL,
	[Returned Quantity By _itemID] [int] NOT NULL,
	[Units Sold By _itemID] [int] NOT NULL,
	[Complaint Rate By _itemID] [decimal](38, 20) NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
ALTER TABLE [ext].[QualityReturnedProducts] ADD  CONSTRAINT [PK__QualityReturnedProducts] PRIMARY KEY CLUSTERED 
(
	[_batchID] ASC,
	[Return Year] ASC,
	[_keyQualityType] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO