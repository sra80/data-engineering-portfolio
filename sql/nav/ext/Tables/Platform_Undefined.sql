CREATE TABLE [ext].[Platform_Undefined] (
    [company_id]       INT              NOT NULL,
    [Integration_Code] NVARCHAR (32)    NOT NULL,
    [Channel_Code]     NVARCHAR (32)    NOT NULL,
    [Order_Prefix]     NVARCHAR (10)    NOT NULL,
    [AddedTSUTC]       DATETIME2 (0)    NOT NULL,
    [place_holder]     UNIQUEIDENTIFIER NOT NULL
);
GO

ALTER TABLE [ext].[Platform_Undefined]
    ADD CONSTRAINT [DF__Platform_Undefined__AddedTSUTC] DEFAULT (getutcdate()) FOR [AddedTSUTC];
GO

ALTER TABLE [ext].[Platform_Undefined]
    ADD CONSTRAINT [PK__Platform_Undefined] PRIMARY KEY CLUSTERED ([company_id] ASC, [Integration_Code] ASC, [Channel_Code] ASC, [Order_Prefix] ASC);
GO
