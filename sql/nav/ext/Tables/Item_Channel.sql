create table ext.Item_Channel
    (
        item_id int not null,
        channel_id int not null,
        occurrence int not null,
        is_current bit not null,
        tsOn datetime2(3) not null,
        tsOff datetime2(3) null
    )
go

alter table ext.Item_Channel add constraint PK__Item_Channel primary key (item_id, channel_id, occurrence)
go

alter table ext.Item_Channel add constraint DF__Item_Channel__is_current default 0 for is_current
go

alter table ext.Item_Channel add constraint DF__Item_Channel__occurrence default 0 for occurrence
go

alter table ext.Item_Channel add constraint DF__Item_Channel__tsOn default sysdatetime() for tsOn
go

create unique index IX__6DD on ext.Item_Channel (item_id, channel_id) where (is_current = 1)
go

--initial population
/*
insert into ext.Item_Channel (item_id, channel_id, occurrence, is_current, tsOn, tsOff)
select
    i.ID,
    c.ID,
    0,
    1,
    getutcdate(),
    case when ic.company_id is null then getutcdate() end
from
    ext.Item i
cross apply
    ext.Channel c
left join
    hs_consolidated.[Item Channel] ic
on
    (
        i.company_id = ic.company_id
    and i.No_ = ic.[Item No_]
    and c.Channel_Code = ic.[Channel Code]
    )
where
    (
        i.company_id = c.company_id
    )
*/  