SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ext].[ChartOfAccounts](
	[keyTransactionDate] [int] NOT NULL,
	[Transaction Type] [nvarchar](8) NOT NULL,
	[keyGLAccountNo] [nvarchar](40) NOT NULL,
	[keyDimensionSetID] [int] NOT NULL,
	[keyCountryCode] [nvarchar](5) NOT NULL,
	[Management Heading] [nvarchar](50) NULL,
	[Management Category] [nvarchar](50) NULL,
	[Heading Sort] [int] NOT NULL,
	[Category Sort] [int] NOT NULL,
	[main] [bit] NOT NULL,
	[invert] [bit] NOT NULL,
	[ma] [bit] NOT NULL,
	[Channel Category] [nvarchar](50) NULL,
	[Channel Sort] [int] NOT NULL,
	[Amount] [decimal](38, 20) NULL,
	[_company] [tinyint] NOT NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
ALTER TABLE [ext].[ChartOfAccounts] ADD  CONSTRAINT [PK__ChartOfAccounts] PRIMARY KEY CLUSTERED 
(
	[keyTransactionDate] ASC,
	[Transaction Type] ASC,
	[keyGLAccountNo] ASC,
	[keyDimensionSetID] ASC,
	[keyCountryCode] ASC,
	[Heading Sort] ASC,
	[Category Sort] ASC,
	[Channel Sort] ASC,
	[_company] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
CREATE NONCLUSTERED INDEX [IX__7DF] ON [ext].[ChartOfAccounts]
(
	[Transaction Type] ASC,
	[keyGLAccountNo] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [ext].[ChartOfAccounts] ADD  CONSTRAINT [DF__ChartOfAccounts__main]  DEFAULT ((1)) FOR [main]
GO
ALTER TABLE [ext].[ChartOfAccounts] ADD  CONSTRAINT [DF__ChartOfAccounts___company]  DEFAULT ((1)) FOR [_company]
GO