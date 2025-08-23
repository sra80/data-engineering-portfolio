CREATE TABLE [stg].[Sales_Line_Archive] (
    [company_id]                INT           NOT NULL,
    [Document Type]             INT           NOT NULL,
    [Document No_]              NVARCHAR (20) NOT NULL,
    [Doc_ No_ Occurrence]       INT           NOT NULL,
    [Version No_]               INT           NOT NULL,
    [Line No_]                  INT           NOT NULL,
    [addTS]                     datetime2(3)  NOT NULL,
    [place_holder]                uniqueidentifier NULL,
    [archiveTS]                   datetime2(3)     null
);
GO

ALTER TABLE [stg].[Sales_Line_Archive]
    ADD CONSTRAINT [PK__Sales_Line_Archive] PRIMARY KEY CLUSTERED ([company_id] ASC, [Document Type] ASC, [Document No_] ASC, [Doc_ No_ Occurrence] ASC, [Version No_] ASC, [Line No_] ASC);
GO


ALTER TABLE [stg].[Sales_Line_Archive]
    ADD CONSTRAINT [DF__Sales_Line_Archive__addTS] default (getutcdate()) for addTS
GO

create index IX__0CC on [stg].[Sales_Line_Archive] (place_holder)
go