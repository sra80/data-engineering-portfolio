CREATE TABLE [ext].[Posted_Whse_Line] (
    [No_]                       NVARCHAR (20)    NOT NULL,
    [Line No_]                  INT              NOT NULL,
    [Whse_ Shipment No_]        NVARCHAR (20)    NOT NULL,
    [Whse Shipment Line No_]    INT              NOT NULL,
    [Shipment Created Datetime] DATETIME         NOT NULL,
    [Quantity]                  DECIMAL (38, 20) NOT NULL,
    [Location Code]             NVARCHAR (10)    NOT NULL,
    [Channel Code]              NVARCHAR (10)    NOT NULL,
    [Source No_]                NVARCHAR (20)    NOT NULL,
    [Source Line No_]           INT              NOT NULL,
    [Item No_]                  NVARCHAR (20)    NOT NULL,
    [company_id]                INT              NOT NULL
);
GO

ALTER TABLE [ext].[Posted_Whse_Line]
    ADD CONSTRAINT [FK__Posted_Whse_Line__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

CREATE NONCLUSTERED INDEX [IX__D7F]
    ON [ext].[Posted_Whse_Line]([Shipment Created Datetime] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__BDA]
    ON [ext].[Posted_Whse_Line]([Source No_] ASC, [Source Line No_] ASC, [Item No_] ASC);
GO

ALTER TABLE [ext].[Posted_Whse_Line]
    ADD CONSTRAINT [PK__Posted_Whse_Line] PRIMARY KEY CLUSTERED ([company_id] ASC, [No_] ASC, [Line No_] ASC);
GO
