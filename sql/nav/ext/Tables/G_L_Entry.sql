CREATE TABLE [ext].[G_L_Entry] (
    [entry_no]       INT          NOT NULL,
    [posting_date]   DATE         NOT NULL,
    [country_region] NVARCHAR (2) NOT NULL,
    [_company]       TINYINT      NOT NULL
);
GO

ALTER TABLE [ext].[G_L_Entry]
    ADD CONSTRAINT [DF__G_L_Entry___company] DEFAULT ((1)) FOR [_company];
GO

ALTER TABLE [ext].[G_L_Entry]
    ADD CONSTRAINT [PK__G_L_Entry] PRIMARY KEY CLUSTERED ([_company] ASC, [entry_no] ASC);
GO
