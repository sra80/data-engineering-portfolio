CREATE   view [price_tool_feed].[vw_sales_files]

as

select
    _file,
    sum(1) row_count,
    concat('(_file eq ',_file,')') _filter,
    concat('sales_',format(_file,'00'),'.csv') _filename_sales,
    concat('rejection_flags_',format(_file,'00'),'.csv') _filename_reject,
    concat('hs-bi-datawarehouse-price_tool_feed (sales/sales_',format(_file,'00'),'.csv)') _eventname_sales,
    concat('hs-bi-datawarehouse-price_tool_feed (rejection_flags/rejection_flags_',format(_file,'00'),'.csv)') _eventname_reject
from
    price_tool_feed.vw_sales
group by
    _file
GO
