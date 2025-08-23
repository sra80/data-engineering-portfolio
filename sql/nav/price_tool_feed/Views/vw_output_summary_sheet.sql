create or alter view price_tool_feed.vw_output_summary_sheet

as

select
    file_path [File],
    format(row_count,'###,###,##0') [Row Count]
from
    price_tool_feed.output_summary_sheet y_oss
where
    (
        y_oss.is_current = 1
    )