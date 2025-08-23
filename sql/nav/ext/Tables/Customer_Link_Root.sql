CREATE TABLE [ext].[Customer_Link_Root] (
    [ID]    INT            IDENTITY (0, 1) NOT NULL,
    [email] NVARCHAR (255) NOT NULL
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__BA5]
    ON [ext].[Customer_Link_Root]([email] ASC);
GO

ALTER TABLE [ext].[Customer_Link_Root]
    ADD CONSTRAINT [PK__Customer_Link_Root] PRIMARY KEY CLUSTERED ([ID] ASC);
GO
