CREATE TABLE [finance].[nominal_codes] (
    [cus]        NVARCHAR (20) NOT NULL,
    [G_L_Code]   NVARCHAR (20) NOT NULL,
    [addedTSUTC] DATETIME2 (1) NOT NULL
);
GO

ALTER TABLE [finance].[nominal_codes]
    ADD CONSTRAINT [DF__nominal_codes__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO

ALTER TABLE [finance].[nominal_codes]
    ADD CONSTRAINT [PK__nominal_codes] PRIMARY KEY CLUSTERED ([cus] ASC);
GO
