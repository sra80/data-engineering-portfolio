<<<<<<< HEAD
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [ext].[Return_Receipt_Line](
	[id] [int] IDENTITY(0,1) NOT NULL,
	[company_id] [int] NOT NULL,
	[Document No_] [nvarchar](20) NOT NULL,
	[Line No_] [int] NOT NULL,
	[is_QR] [bit] NOT NULL,
	[QR_processTS] [datetime2](3) NULL,
	[addTS] [datetime2](3) NOT NULL,
	[batch_id] [int] NULL
) ON [PRIMARY]
GO
ALTER TABLE [ext].[Return_Receipt_Line] ADD  CONSTRAINT [PK__Return_Receipt_Line] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX__202] ON [ext].[Return_Receipt_Line]
(
	[batch_id] ASC
)
WHERE ([batch_id] IS NULL)
WITH (STATISTICS_NORECOMPUTE = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
SET ANSI_PADDING ON
GO
CREATE UNIQUE NONCLUSTERED INDEX [IX__8AE] ON [ext].[Return_Receipt_Line]
(
	[company_id] ASC,
	[Document No_] ASC,
	[Line No_] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO
ALTER TABLE [ext].[Return_Receipt_Line] ADD  CONSTRAINT [DF__Return_Receipt_Line__is_QR]  DEFAULT ((0)) FOR [is_QR]
GO
ALTER TABLE [ext].[Return_Receipt_Line] ADD  CONSTRAINT [DF__Return_Receipt_Line__is_addTS]  DEFAULT (getutcdate()) FOR [addTS]
GO
=======
create table ext.Return_Receipt_Line
    (
        id int identity(0,1),
        company_id int not null,
        [Document No_] nvarchar(20) not null,
        [Line No_] int not null,
        is_QR bit not null, --quality return
        QR_processTS datetime2(3) null,
        batch_id int null,
        sales_line_id int,
        addTS datetime2(3) not null
    constraint PK__Return_Receipt_Line primary key (id)
    )
go

alter table ext.Return_Receipt_Line add constraint DF__Return_Receipt_Line__is_QR default 0 for is_QR
go

alter table ext.Return_Receipt_Line add constraint DF__Return_Receipt_Line__is_addTS default getutcdate() for addTS
go

create unique index IX__8AE on ext.Return_Receipt_Line (company_id, [Document No_], [Line No_])
go

create index IX__202 on ext.Return_Receipt_Line (is_QR, batch_id) where (is_QR  = 1 and batch_id is null)
go
>>>>>>> 176baa477133bcde01583fa4587db347f6065433
GO
CREATE NONCLUSTERED INDEX IX__AB2
ON [ext].[Return_Receipt_Line] ([batch_id])