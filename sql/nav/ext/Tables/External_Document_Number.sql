CREATE TABLE [ext].[External_Document_Number] (
    [ID]                    INT           IDENTITY (0, 1) NOT NULL,
    [External Document No_] NVARCHAR (35) NOT NULL,
    [addedTSUTC]            DATETIME2 (0) NOT NULL,
    [company_id]            INT           NOT NULL
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__ED3]
    ON [ext].[External_Document_Number]([company_id] ASC, [External Document No_] ASC);
GO

ALTER TABLE [ext].[External_Document_Number]
    ADD CONSTRAINT [PK__External_Document_Number] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

ALTER TABLE [ext].[External_Document_Number]
    ADD CONSTRAINT [DF__External_Document_Number__addedTSUTC] DEFAULT (getutcdate()) FOR [addedTSUTC];
GO

ALTER TABLE [ext].[External_Document_Number]
    ADD CONSTRAINT [FK__External_Document_Number__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO
