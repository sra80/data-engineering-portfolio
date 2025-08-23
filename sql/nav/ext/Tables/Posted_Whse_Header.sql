CREATE TABLE [ext].[Posted_Whse_Header] (
    [No_]                 NVARCHAR (20) NOT NULL,
    [Whse_ Shipment Type] INT           NOT NULL,
    [company_id]          INT           NOT NULL
);
GO

CREATE NONCLUSTERED INDEX [IX__AC9]
    ON [ext].[Posted_Whse_Header]([No_] ASC)
    INCLUDE([Whse_ Shipment Type]);
GO

ALTER TABLE [ext].[Posted_Whse_Header]
    ADD CONSTRAINT [PK__Posted_Whse_Header] PRIMARY KEY CLUSTERED ([company_id] ASC, [No_] ASC, [Whse_ Shipment Type] ASC);
GO

ALTER TABLE [ext].[Posted_Whse_Header]
    ADD CONSTRAINT [FK__Posted_Whse_Header__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO
