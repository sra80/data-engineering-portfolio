create or alter view price_tool_feed.import_outcome

as

select
  blob_id,
  case when y_if.is_invalid = 1 or y_er.filelist_id > 0 then 'Outcome: Failed' else 'Outcome: Success' end outcome
from
  price_tool_feed.import_filelist y_if
left join
  price_tool_feed.import_errors y_er
on
  (
    y_if.id = y_er.filelist_id
  )