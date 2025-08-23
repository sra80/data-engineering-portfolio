SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ext].[Registered_Pick_Line](
	[No_] [nvarchar](20) NOT NULL,
	[Activity Type] [int] NOT NULL,
	[Line No_] [int] NOT NULL,
	[Starting Date] [datetime] NOT NULL,
	[Registered DateTime] [datetime] NOT NULL,
	[Whse_ Document Type] [int] NOT NULL,
	[Whse_ Document No_] [nvarchar](20) NOT NULL,
	[Source Type] [int] NOT NULL,
	[Source Line No_] [int] NOT NULL,
	[Source No_] [nvarchar](20) NOT NULL,
	[Item No_] [nvarchar](20) NOT NULL,
	[Quantity] [decimal](38, 20) NOT NULL,
	[Whse_ Document Line No_] [int] NULL,
	[Shipping Agent] [nvarchar](10) NOT NULL,
	[Shipping Agent Service] [nvarchar](10) NOT NULL,
	[company_id] [int] NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
ALTER TABLE [ext].[Registered_Pick_Line] ADD  CONSTRAINT [PK__Registered_Pick_Line] PRIMARY KEY CLUSTERED 
(
	[company_id] ASC,
	[Activity Type] ASC,
	[No_] ASC,
	[Line No_] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX__AF6] ON [ext].[Registered_Pick_Line]
(
	[Activity Type] ASC,
	[company_id] ASC,
	[Source No_] ASC,
	[Registered DateTime] ASC
)
INCLUDE([Quantity]) WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX__B17] ON [ext].[Registered_Pick_Line]
(
	[Activity Type] ASC,
	[No_] ASC
)
INCLUDE([Whse_ Document No_],[Source No_],[Item No_],[Quantity],[Shipping Agent],[Shipping Agent Service]) WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX__EA9] ON [ext].[Registered_Pick_Line]
(
	[Activity Type] ASC,
	[Source Line No_] ASC,
	[Source No_] ASC,
	[Item No_] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [ext].[Registered_Pick_Line]  WITH CHECK ADD  CONSTRAINT [FK__Registered_Pick_Line__company_id] FOREIGN KEY([company_id])
REFERENCES [db_sys].[Company] ([ID])
GO
ALTER TABLE [ext].[Registered_Pick_Line] CHECK CONSTRAINT [FK__Registered_Pick_Line__company_id]
GO