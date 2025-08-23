drop table if exists price_tool_feed.subs_fixed_discount
go

create table price_tool_feed.subs_fixed_discount
  (
    pricetype_id int not null,
    price_group_id int not null,
    price money not null,
    discount money not null,
    addTS datetime2(0) not null,
  constraint PK__subs_fixed_discount primary key (pricetype_id, price_group_id, price)
  )
go

alter table price_tool_feed.subs_fixed_discount add constraint FK__subs_fixed_discount__pricetype_id foreign key (pricetype_id) references price_tool_feed.import_pricetype (id)
go

alter table price_tool_feed.subs_fixed_discount add constraint FK__subs_fixed_discount__price_group_id foreign key (price_group_id) references ext.Customer_Price_Group (id)
go

alter table price_tool_feed.subs_fixed_discount add constraint DF__subs_fixed_discount__addTS default getutcdate() for addTS
go

insert into price_tool_feed.subs_fixed_discount (pricetype_id, price_group_id, price, discount)
select
    2, 120, 0, 0

union all

select
    2, 120, 1.01, 1

union all

select
    2, 120, 10.01, 2

union all

select
    2, 120, 25.01, 3
union all

select
    2, 120, 35.01, 4

union all

select
    2, 120, 45.01, 5

union all

select
    2, 122, 0, 0

union all

select
    2, 122, 1.01, 1

union all

select
    2, 122, 10.01, 2

union all

select
    2, 122, 25.01, 3
union all

select
    2, 122, 35.01, 4

union all

select
    2, 122, 45.01, 5


go

select * from price_tool_feed.subs_fixed_discount