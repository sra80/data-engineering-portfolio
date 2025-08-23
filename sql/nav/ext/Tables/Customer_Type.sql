SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ext].[Customer_Type](
	[ID] [int] IDENTITY(0,1) NOT NULL,
	[nav_code] [nvarchar](10) NOT NULL,
	[is_anon] [bit] NOT NULL,
	[addedTSUTC] [datetime2](0) NOT NULL,
	[is_retailAcc] [bit] NOT NULL,
	[company_id] [int] NOT NULL,
	[ID_grp] [int] NULL,
	[default_sale_channel] [nvarchar](20) NULL,
	[tnc_ID] [int] NULL --used in alerts 79 & 80
) ON [PRIMARY]
GO
ALTER TABLE [ext].[Customer_Type] ADD  CONSTRAINT [PK__Customer_Type] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX__54B] ON [ext].[Customer_Type]
(
	[company_id] ASC,
	[nav_code] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [ext].[Customer_Type] ADD  CONSTRAINT [DF__Customer_Type__is_anon]  DEFAULT ((1)) FOR [is_anon]
GO
ALTER TABLE [ext].[Customer_Type] ADD  CONSTRAINT [DF__Customer_Type__addedTSUTC]  DEFAULT (getutcdate()) FOR [addedTSUTC]
GO
ALTER TABLE [ext].[Customer_Type] ADD  CONSTRAINT [DF__Customer_Type__is_retailAcc]  DEFAULT ((0)) FOR [is_retailAcc]
GO
ALTER TABLE [ext].[Customer_Type]  WITH CHECK ADD  CONSTRAINT [FK__Customer_Type__company_id] FOREIGN KEY([company_id])
REFERENCES [db_sys].[Company] ([ID])
GO
ALTER TABLE [ext].[Customer_Type] CHECK CONSTRAINT [FK__Customer_Type__company_id]
GO
ALTER TABLE [ext].[Customer_Type]  WITH CHECK ADD  CONSTRAINT [FK__Customer_Type__tnc_ID] FOREIGN KEY([tnc_ID])
REFERENCES [db_sys].[team_notification_channels] ([ID])
GO
