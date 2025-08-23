CREATE TABLE [ext].[iOSS] (
    [Invoice No]                 NVARCHAR (20)    NOT NULL,
    [Customer]                   NVARCHAR (50)    NOT NULL,
    [Customer No]                NVARCHAR (20)    NOT NULL,
    [Delivery Country]           NVARCHAR (10)    NOT NULL,
    [Customer Country]           NVARCHAR (10)    NOT NULL,
    [Order Date]                 DATETIME         NOT NULL,
    [Payment Date]               DATETIME         NOT NULL,
    [Order No]                   NVARCHAR (20)    NOT NULL,
    [Invoice Date]               DATETIME         NULL,
    [Line No]                    INT              NOT NULL,
    [Item No]                    NVARCHAR (20)    NOT NULL,
    [Item Description]           NVARCHAR (50)    NOT NULL,
    [Catalogue Code]             NVARCHAR (20)    NOT NULL,
    [VAT Business Posting Group] NVARCHAR (10)    NOT NULL,
    [VAT Product Posting Group]  NVARCHAR (10)    NOT NULL,
    [Quantity]                   DECIMAL (38)     NOT NULL,
    [Unit of Measure Code]       NVARCHAR (10)    NOT NULL,
    [Unit Price]                 DECIMAL (38, 20) NOT NULL,
    [Amount Including VAT]       DECIMAL (38, 2)  NOT NULL,
    [VAT Amount]                 DECIMAL (38, 2)  NOT NULL,
    [Line Discount Amount]       DECIMAL (38, 2)  NOT NULL,
    [Manual Discount Amount]     DECIMAL (38, 2)  NOT NULL,
    [Promotion Discount Amount]  DECIMAL (38, 2)  NOT NULL,
    [System Discount Amount]     DECIMAL (38, 2)  NOT NULL,
    [iOSS Amount]                DECIMAL (38, 2)  NOT NULL,
    [iOSS Amount Including VAT]  DECIMAL (38, 2)  NOT NULL,
    [iOSS VAT Amount]            DECIMAL (38, 2)  NOT NULL,
    [iOSS Amount (LCY)]          DECIMAL (38, 2)  NOT NULL
);
GO

GRANT SELECT
    ON OBJECT::[ext].[iOSS] TO [Finance_Users]
    AS [dbo];
GO

ALTER TABLE [ext].[iOSS]
    ADD CONSTRAINT [PK__iOSS] PRIMARY KEY CLUSTERED ([Invoice No] ASC, [Order No] ASC, [Line No] ASC, [Item No] ASC);
GO
