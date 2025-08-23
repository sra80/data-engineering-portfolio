create table price_tool_feed.tb_sales
    (
        _file int not null,
        id int not null,
        store_id int not null,
        article_id int not null,
        [date] date not null,
        price_type int not null,
        quantity int not null,
        price money not null,
        shelf_price money not null,
        cost_price money not null,
        customer_id int not null,
        [0] bit not null,
        [1] bit not null,
        [2] bit not null,
        [3] bit not null,
        [4] bit not null,
        [5] bit not null
    constraint PK__tb_sales primary key (id)
    )