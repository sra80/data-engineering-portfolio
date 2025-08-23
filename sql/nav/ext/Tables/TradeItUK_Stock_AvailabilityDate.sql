SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ext].[TradeItUK_Stock_AvailabilityDate](
    [ProductCode] [nvarchar](20) NOT NULL,
    [WarehouseCode] [nvarchar](20) NOT NULL,
    [AvailabilityDate] [date] NOT NULL,
    [InsertedUTC] [datetime2](0) NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
ALTER TABLE [ext].[TradeItUK_Stock_AvailabilityDate] ADD  CONSTRAINT [PK__TradeItUK_Stock_AvailabilityDate] PRIMARY KEY CLUSTERED 
(
	[ProductCode] ASC,
    [InsertedUTC] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO