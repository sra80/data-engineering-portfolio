SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ext].[IE_Outbound_Stock_Availability](
	[sku] [nvarchar](20) NOT NULL,
	[AvailableQuantity] [int] NOT NULL,
	[UpdatedTSUTC] [datetime2](0) NULL,
	[is_LowStock] [uniqueidentifier] NULL,
	[is_OOS] [uniqueidentifier] NULL,
	[is_BackInStock] [uniqueidentifier] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
ALTER TABLE [ext].[IE_Outbound_Stock_Availability] ADD  CONSTRAINT [PK__IE_Outbound_Stock_Availability] PRIMARY KEY CLUSTERED 
(
	[sku] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO