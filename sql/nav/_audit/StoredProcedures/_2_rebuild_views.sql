create or alter procedure _audit._2_rebuild_views

as

declare @sql nvarchar(max)

declare [c463fe6c-8796-4a63-a0e0-f81116dc6829] cursor for

select
    concat('create or alter view _audit.',v.[2],' as select d.* from ',r._list,' d',case when len(r._date_column) > 0 then concat(' cross apply _audit._1_date_range a where d.',r._date_column,' >= a._date_from and d.',r._date_column,' <= a._date_to') end)
from
    _audit._0_table_list r
cross apply
    db_sys.string_split(_list,'.') v

open [c463fe6c-8796-4a63-a0e0-f81116dc6829]

fetch next from [c463fe6c-8796-4a63-a0e0-f81116dc6829] into @sql

while @@fetch_status = 0

begin

exec (@sql)

fetch next from [c463fe6c-8796-4a63-a0e0-f81116dc6829] into @sql

end

close [c463fe6c-8796-4a63-a0e0-f81116dc6829]
deallocate [c463fe6c-8796-4a63-a0e0-f81116dc6829]

go