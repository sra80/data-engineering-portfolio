CREATE TABLE [ext].[Sale_Channel_Exceptions] (
    [customer_no_]  NVARCHAR (20) NOT NULL,
    [customer_type] NVARCHAR (10) NOT NULL,
    [sale_channel]  NVARCHAR (20) NOT NULL,
    [AddedTSUTC]    DATETIME2 (0) NOT NULL,
    [company_id]    INT           NOT NULL
);
GO

ALTER TABLE [ext].[Sale_Channel_Exceptions]
    ADD CONSTRAINT [DF__Sale_Channel_Exceptions__AddedTSUTC] DEFAULT (getutcdate()) FOR [AddedTSUTC];
GO

ALTER TABLE [ext].[Sale_Channel_Exceptions]
    ADD CONSTRAINT [FK__Sale_Channel_Exceptions__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

ALTER TABLE [ext].[Sale_Channel_Exceptions]
    ADD CONSTRAINT [PK__Sale_Channel_Exceptions] PRIMARY KEY CLUSTERED ([company_id] ASC, [customer_no_] ASC);
GO