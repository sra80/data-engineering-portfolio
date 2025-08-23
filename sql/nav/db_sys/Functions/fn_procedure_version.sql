CREATE function [db_sys].[fn_procedure_version]
    (
        @procedureName nvarchar(64)
    )

returns nvarchar(2)

as

begin

declare @script nvarchar(max), @version int, @procedureNameNew nvarchar(64) = ''

;with n as (select 2 c, left(@procedureName,1) s union all select c + 1, substring(@procedureName,c,1) from n where c < len(@procedureName)+1)

select @procedureNameNew += s from n where patindex('%[a-zA-Z0-9._]%',s) = 1

set @procedureName = @procedureNameNew

-- if charindex(char(32),@procedureName) > 0 set @procedureName = left(@procedureName,charindex(char(32),@procedureName)-1)

select @script = object_definition(object_id(@procedureName))

set @script = left(@script,patindex('%*/%',@script))

;with n as
    (
        select 1 row_num, @script script, left(@script,charindex(char(10),@script)) script_part,charindex(char(10),@script) break_index, len(@script)-1 script_len 

        union all

        select row_num + 1, script, substring(script,break_index+1,charindex(char(10),script,break_index+1)), charindex(char(10),script,break_index+1), script_len from n where break_index < script_len and row_num < 100

    )

select @version = max(try_convert(int,left(script_part,2))) from n

return isnull(format(@version,'00'),'00')

end
GO
