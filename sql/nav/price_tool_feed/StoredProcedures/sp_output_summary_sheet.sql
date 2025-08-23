create or alter procedure price_tool_feed.sp_output_summary_sheet

as

update price_tool_feed.output_summary_sheet set is_current = 0 where is_current = 1