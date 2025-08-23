CREATE TABLE [ext].[Customer_Amazon] (
    [hs_cus]      NVARCHAR (32) NOT NULL,
    [am_add_code] NVARCHAR (32) NOT NULL,
    [addedTSUTC]  DATETIME2 (1) NOT NULL
);
GO

ALTER TABLE [ext].[Customer_Amazon]
    ADD CONSTRAINT [PK__Customer_Amazon] PRIMARY KEY CLUSTERED ([hs_cus] ASC, [am_add_code] ASC);
GO

ALTER TABLE [ext].[Customer_Amazon]
    ADD CONSTRAINT [DF__Customer_Amazon__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO
