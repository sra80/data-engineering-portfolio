CREATE TABLE [ext].[SS_Payment_Attempts] (
    [Attempt ID]           INT            NOT NULL,
    [External Document No] NVARCHAR (35)  NOT NULL,
    [Attempt]              NVARCHAR (20)  NOT NULL,
    [Processing Status]    NVARCHAR (10)  NOT NULL,
    [Error]                NVARCHAR (250) NULL,
    [Attempt Date]         DATETIME2 (0)  NOT NULL,
    [Subscription]         NVARCHAR (20)  NOT NULL,
    [Customer]             NVARCHAR (20)  NOT NULL
);
GO

ALTER TABLE [ext].[SS_Payment_Attempts]
    ADD CONSTRAINT [PK__SS_Payment_Attempts] PRIMARY KEY CLUSTERED ([Attempt ID] ASC);
GO

GRANT SELECT
    ON OBJECT::[ext].[SS_Payment_Attempts] TO [All CompanyX Staff]
    AS [dbo];
GO
