CREATE TABLE [stg].[Sales_Header_Archive] (
    [company_id]                  INT              NOT NULL,
    [Document Type]               INT              NOT NULL,
    [No_]                         NVARCHAR (20)    NOT NULL,
    [Doc_ No_ Occurrence]         INT              NOT NULL,
    [Version No_]                 INT              NOT NULL,
    [addTS]                       datetime2(3)     not null,
    [place_holder]                  uniqueidentifier null,
    [archiveTS]                   datetime2(3)     null
);
GO

ALTER TABLE [stg].[Sales_Header_Archive]
    ADD CONSTRAINT [PK__Sales_Header_Archive] PRIMARY KEY CLUSTERED ([company_id] ASC, [Document Type] ASC, [No_] ASC, [Doc_ No_ Occurrence] ASC, [Version No_] ASC);
GO

alter table [stg].[Sales_Header_Archive] add constraint DF__Sales_Header_Archive__addTS default getutcdate() for addTS
go

create index IX__AF5 on [stg].[Sales_Header_Archive] (place_holder)
go