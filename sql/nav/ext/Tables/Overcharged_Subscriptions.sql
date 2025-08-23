CREATE TABLE [ext].[Overcharged_Subscriptions]
(
  [is_resolved] [bit] NOT NULL,
  [Order Date] [date] NOT NULL,
  [Order No] [nvarchar](20) NOT NULL,
  [Subscription No] [nvarchar](20) NULL,
  [Customer No] [nvarchar](40) NOT NULL,
	[Item No]	[nvarchar](40) NOT NULL,
  [Quantity] [int] NOT NULL,
  [Gross Revenue Charged] [money] NOT NULL,
  [Accurate Amount] [money] NOT NULL,
  [Overcharged Amount] [money] NOT NULL,
  [Collected Amount] [money] NOT NULL,
  [Refunded Amount] [money] NOT NULL,
  [Price Group] [nvarchar](20) NOT NULL,
 CONSTRAINT [PK__Overcharged_Subscriptions] PRIMARY KEY CLUSTERED 
(
    [Order No] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [ext].[Overcharged_Subscriptions] ADD CONSTRAINT [DF__Overcharged_Subscriptions__is_resolved]  DEFAULT ((0)) FOR [is_resolved]

CREATE NONCLUSTERED INDEX [IX__EB2]
    ON [ext].[Overcharged_Subscriptions]([Order No])
GO