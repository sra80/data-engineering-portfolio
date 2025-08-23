CREATE TABLE [ext].[CC_Sales] (
    [Document Type]       INT              NOT NULL,
    [No_]                 NVARCHAR (20)    NOT NULL,
    [Doc_ No_ Occurrence] INT              NOT NULL,
    [Version No_]         INT              NOT NULL,
    [Media Code]          NVARCHAR (20)    NOT NULL,
    [Line No_]            INT              NOT NULL,
    [Order Date]          DATETIME         NOT NULL,
    [Order Created by]    NVARCHAR (50)    NOT NULL,
    [Channel Code]        NVARCHAR (10)    NOT NULL,
    [Line Type]           INT              NOT NULL,
    [Quantity]            DECIMAL (38, 20) NOT NULL
);
GO

ALTER TABLE [ext].[CC_Sales]
    ADD CONSTRAINT [PK__CC_Sales] PRIMARY KEY CLUSTERED ([Document Type] ASC, [No_] ASC, [Doc_ No_ Occurrence] ASC, [Version No_] ASC, [Line No_] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__308]
    ON [ext].[CC_Sales]([Order Date] ASC);
GO

GRANT SELECT
    ON OBJECT::[ext].[CC_Sales] TO [All CompanyX Staff]
    AS [dbo];
GO
