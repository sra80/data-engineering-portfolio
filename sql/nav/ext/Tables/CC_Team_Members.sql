CREATE TABLE [ext].[CC_Team_Members] (
    [Team]      NVARCHAR (40) NOT NULL,
    [User ID]   NVARCHAR (40) NOT NULL,
    [User Name] NVARCHAR (50) NULL
);
GO

GRANT SELECT
    ON OBJECT::[ext].[CC_Team_Members] TO [logic_app]
    AS [dbo];
GO

GRANT SELECT
    ON OBJECT::[ext].[CC_Team_Members] TO [All CompanyX Staff]
    AS [dbo];
GO

ALTER TABLE [ext].[CC_Team_Members]
    ADD CONSTRAINT [PK__CC_Team_Members] PRIMARY KEY CLUSTERED ([User ID] ASC);
GO