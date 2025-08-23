
CREATE procedure [db_sys].[sp_objects_change_control]

as

/*
 Description:		Maintains script version control in db_sys.objects_change_control & object listing (db_sys.objects)
 Project:			112
 Creator:			Shaun Edwards(SE)
 Copyright:			CompanyX Limited, 2022
MOD	DATE	INITS	COMMENTS
00  220304  SE      Created
01  220308  SE      Added merge script to maintain db_sys.objects
02  220622  SE      Added merge script to maintain db_sys.schemas
03  220711  SE      Add change control to synonyms
04  230130  SE      Add change control to tables
05  230220  SE      Add parent_object_id
*/

set nocount on

declare @object_id int, @modify_date datetime2(3), @version_id int, @modify_date_cc datetime2(3), @object_definition nvarchar(max)

insert into db_sys.objects_change_control ([object_id],version_id,[object_definition],modify_date,addedTSUTC)
select 
    s.object_id,
    isnull(h.version_id+1,0),
    isnull(object_definition(s.object_id),db_sys.fn_table_definition(s.object_id)),
    s.modify_date,
    sysdatetime()
from
    sys.objects s
left join
    (
        select
            occ.object_id,
            occ.version_id,
            occ.modify_date
        from
            db_sys.objects_change_control occ
        join
            (
                select
                    object_id,
                    max(version_id) version_id
                from
                    db_sys.objects_change_control
                group by
                    object_id
            ) _current
        on
            (
                occ.object_id = _current.object_id
            and occ.version_id = _current.version_id
            )
    ) h
on
    (
        s.object_id = h.object_id
    )
where
    (
        abs(datediff(second,h.modify_date,s.modify_date)) > 1
    or  h.modify_date is null
    and
        (
            s.[type] = N'U'
        or  object_definition(s.object_id) is not null
        )
    )

-- begin

declare [f2e087c2-05ed-4b02-bb5e-074614cd3ccb] cursor for select object_id, modify_date, concat('create synonym [',db_sys.fn_schema_name(schema_id),'].[',[name],'] for ',[base_object_name]) _object_definition from sys.synonyms

open [f2e087c2-05ed-4b02-bb5e-074614cd3ccb]

fetch next from [f2e087c2-05ed-4b02-bb5e-074614cd3ccb] into @object_id, @modify_date, @object_definition

while @@fetch_status = 0

begin

select top 1 @version_id = version_id, @modify_date_cc = modify_date from db_sys.objects_change_control where object_id = @object_id order by version_id desc

if @version_id is null or @modify_date > @modify_date_cc 

    insert into db_sys.objects_change_control ([object_id],version_id,[object_definition],modify_date,addedTSUTC)
    values (@object_id,isnull(@version_id,-1)+1,@object_definition,@modify_date,getutcdate())

fetch next from [f2e087c2-05ed-4b02-bb5e-074614cd3ccb] into @object_id, @modify_date, @object_definition

end

close [f2e087c2-05ed-4b02-bb5e-074614cd3ccb]
deallocate [f2e087c2-05ed-4b02-bb5e-074614cd3ccb]

-- end

merge db_sys.objects t
using sys.objects s
on (t.object_id = s.object_id)
when not matched by target then
    insert (object_id, parent_object_id, schema_id, object_name, object_type, create_date, modify_date)
    values (s.object_id, s.parent_object_id, s.schema_id, s.name, s.type, s.create_date, s.modify_date)
when matched and (s.modify_date > t.modify_date) then update set
    t.schema_id = s.schema_id,
    t.parent_object_id = s.parent_object_id,
    t.object_name = s.name,
    t.object_type = s.type,
    t.create_date = s.create_date,
    t.modify_date = s.modify_date
when not matched by source and delete_date is null then update set delete_date = getutcdate();

merge db_sys.schemas t
using sys.schemas s
on (t.schema_id = s.schema_id)
when not matched by target then
    insert ([schema_name], [schema_id])
    values (s.[name], s.[schema_id])
when matched and (s.[name] != t.[schema_name] collate database_default) then update set
    t.[schema_name] = s.[name],
    t.updatedTSUTC = getutcdate()
when not matched by source and deletedTSUTC is null then update set deletedTSUTC = getutcdate();
GO
