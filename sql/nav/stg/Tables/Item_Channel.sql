create table stg.Item_Channel
    (
        company_id int,
        [Item No_] nvarchar(20),
        [Channel Code] nvarchar (10),
        addTS datetime2(3),
        is_insert bit,
        is_delete bit,
        place_holder uniqueidentifier
    )
go

alter table stg.Item_Channel add constraint DF__Item_Channel__place_holder default newid() for place_holder
go