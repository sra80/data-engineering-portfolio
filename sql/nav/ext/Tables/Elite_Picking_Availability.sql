CREATE TABLE [ext].[Elite_Picking_Availability] (
    [sku]         NVARCHAR (20) NOT NULL,
    [batchNo]     NVARCHAR (20) NOT NULL,
    [whseEntryNo] INT           NOT NULL,
    [AddedTSUTC]  DATETIME2 (0) NOT NULL
);
GO

ALTER TABLE [ext].[Elite_Picking_Availability]
    ADD CONSTRAINT [PK__Elite_Picking_Availability] PRIMARY KEY CLUSTERED ([sku] ASC, [batchNo] ASC);
GO

ALTER TABLE [ext].[Elite_Picking_Availability]
    ADD CONSTRAINT [DF__Elite_Picking_Availability__AddedTSUTC] DEFAULT (getutcdate()) FOR [AddedTSUTC];
GO
