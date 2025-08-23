CREATE TABLE [ext].[Sales_Line_Amazon] (
    [ile_entry_no]  INT NOT NULL,
    [sales_line_id] INT NOT NULL
);
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__682]
    ON [ext].[Sales_Line_Amazon]([sales_line_id] ASC);
GO

ALTER TABLE [ext].[Sales_Line_Amazon]
    ADD CONSTRAINT [PK__Sales_Line_Amazon] PRIMARY KEY CLUSTERED ([ile_entry_no] ASC);
GO
