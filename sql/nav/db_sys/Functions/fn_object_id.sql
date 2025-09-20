CREATE function [db_sys].[fn_object_id]
     (
        @object_name nvarchar(64)
     )
 
 returns bigint
 
 as
 
 begin
 
 set @object_name = replace(replace(@object_name,']',''),'[','')
 
 declare @object_id bigint
 
 select top 1
     @object_id = o.object_id
 from
     db_sys.objects o
 join
     db_sys.schemas s
 on
     (
         o.schema_id = s.schema_id
     )
 where
     (
         lower(s.schema_name) = case when charindex('.',@object_name) > 0 then lower(left(@object_name,charindex('.',@object_name)-1)) else case when (select sum(1) from db_sys.objects where object_name = @object_name) = 1 then s.schema_name end  end
     and lower(o.object_name) = lower(right(@object_name,len(@object_name)-charindex('.',@object_name)))
     )
order by
    o.delete_date asc, 
    o.modify_date desc
 
return @object_id
 
 end
GO
