
  
  
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [db_sys].[entry_no_tracker](
	[stored_procedure] [nvarchar](64) NOT NULL,
	[table_name] [nvarchar](64) NOT NULL,
	[last_entry] [bigint] NOT NULL,
	[last_update] [datetime2](1) NULL
) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
ALTER TABLE [db_sys].[entry_no_tracker] ADD  CONSTRAINT [PK__entry_no_tracker] PRIMARY KEY CLUSTERED 
(
	[stored_procedure] ASC,
	[table_name] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
