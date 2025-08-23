create or alter procedure price_tool_feed.sp_tb_sales

as

truncate table price_tool_feed.tb_sales

insert into price_tool_feed.tb_sales (_file, id, store_id, article_id, date, price_type, quantity, price, shelf_price, cost_price, customer_id, [0], [1], [2], [3], [4], [5])
select _file, id, store_id, article_id, date, price_type, quantity, price, shelf_price, cost_price, customer_id, [0], [1], [2], [3], [4], [5] from price_tool_feed.vw_sales

        