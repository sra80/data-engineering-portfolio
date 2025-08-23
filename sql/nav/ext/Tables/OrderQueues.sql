SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ext].[OrderQueues](
	[Processing Queue] [nvarchar](20) NOT NULL,
	[Order Date] [date] NOT NULL,
	[Origin Date] [datetime2](1) NULL,
	[Inbound Date] [datetime2](1) NULL,
	[Order Created Date] [datetime2](1) NULL,
	[Released To Whse Date] [datetime2](1) NULL,
	[Whse No] [nvarchar](20) NOT NULL,
	[Picked Date] [datetime2](1) NULL,
	[Pick No] [nvarchar](20) NOT NULL,
	[Pick Line No] [int] NOT NULL,
	[Integration] [nvarchar](40) NULL,
	[Inbound Status] [nvarchar](20) NULL,
	[Inbound Error] [nvarchar](250) NULL,
	[Country Code] [nvarchar](10) NOT NULL,
	[Channel Code] [nvarchar](20) NULL,
	[Dispatch Location] [nvarchar](20) NULL,
	[Order Status] [nvarchar](20) NULL,
	[Warehouse Status] [nvarchar](20) NULL,
	[On Hold Code] [nvarchar](3) NULL,
	[On Hold Reason] [nvarchar](10) NULL,
	[Order No] [nvarchar](20) NOT NULL,
	[Order Line No] [int] NOT NULL,
	[Item No] [nvarchar](40) NOT NULL,
	[picking_required] [tinyint] NOT NULL,
	[OrderCount] [int] NOT NULL,
	[OrderUnits] [int] NOT NULL,
	[Qty Picked By Pick Date] [int] NULL,
	[Qty Picked By Order Line] [int] NULL,
	[Qty Shipped] [int] NULL,
	[Qty Invoiced] [int] NULL,
	[processing_queue] [int] NOT NULL,
	[Document Type] [int] NULL,
	[Doc_ No_ Occurrence] [int] NULL,
	[Version No_] [int] NULL,
	[OrderAmount] [money] NULL,
	[rn] [tinyint] NULL,
	[courier_delivery] [tinyint] NOT NULL,
	[company_id] [int] NOT NULL,
	[Whse Line No] [int] NOT NULL,
	[processing_queue2] [int] NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
ALTER TABLE [ext].[OrderQueues] ADD  CONSTRAINT [PK__OrderQueues] PRIMARY KEY CLUSTERED 
(
	[company_id] ASC,
	[processing_queue] ASC,
	[Whse No] ASC,
	[Whse Line No] ASC,
	[Pick No] ASC,
	[Pick Line No] ASC,
	[Order No] ASC,
	[Order Line No] ASC,
	[Item No] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX__0F4] ON [ext].[OrderQueues]
(
	[Order No] ASC,
	[Order Line No] ASC,
	[Document Type] ASC,
	[Doc_ No_ Occurrence] ASC,
	[Version No_] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX__109] ON [ext].[OrderQueues]
(
	[processing_queue] ASC,
	[Order Date] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX__25E] ON [ext].[OrderQueues]
(
	[Item No] ASC,
	[Order Date] ASC
)
INCLUDE([Picked Date],[OrderCount],[OrderUnits]) WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX__42D] ON [ext].[OrderQueues]
(
	[processing_queue] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX__787] ON [ext].[OrderQueues]
(
	[Order No] ASC
)
INCLUDE([OrderUnits]) WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX__86B] ON [ext].[OrderQueues]
(
	[Order Date] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX__A7E] ON [ext].[OrderQueues]
(
	[Order Date] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX__ADC] ON [ext].[OrderQueues]
(
	[Processing Queue] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX__BFA] ON [ext].[OrderQueues]
(
	[processing_queue2] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [ext].[OrderQueues] ADD  CONSTRAINT [DF__OrderQueues__Whse_No]  DEFAULT ('WAS-00000000') FOR [Whse No]
GO
ALTER TABLE [ext].[OrderQueues] ADD  CONSTRAINT [DF__OrderQueues__Pick_No]  DEFAULT ('WRP-00000000') FOR [Pick No]
GO
ALTER TABLE [ext].[OrderQueues] ADD  CONSTRAINT [DF__OrderQueues__Pick_Line_No]  DEFAULT ((1)) FOR [Pick Line No]
GO
ALTER TABLE [ext].[OrderQueues]  WITH CHECK ADD  CONSTRAINT [FK__OrderQueues__company_id] FOREIGN KEY([company_id])
REFERENCES [db_sys].[Company] ([ID])
GO
ALTER TABLE [ext].[OrderQueues] CHECK CONSTRAINT [FK__OrderQueues__company_id]
GO