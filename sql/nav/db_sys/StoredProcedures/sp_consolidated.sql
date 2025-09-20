create or alter procedure [db_sys].[sp_consolidated]
    (
        @view_rebuild nvarchar(255) = null
    )

as

set nocount on

declare @t table (table_name nvarchar(255), is_new bit, is_existing bit)

if @view_rebuild is null

    begin

        insert into @t (table_name, is_new, is_existing)
        select
            t.name,
            case when v.[table_name] is null then 1 else 0 end is_new,
            case when v.[table_name] is null then 0 else 1 end is_existing
        from
            (
                select
                    right(tables.[name],len(tables.[name])-charindex('$',tables.[name])) collate database_default [name],
                    max(tables.modify_date) modify_date
                from
                    sys.tables
                join
                    db_sys.Company
                on
                    left(tables.[name],charindex('$',tables.[name])-1) = Company.NAV_DB collate database_default
                where
                    (
                        charindex('$',tables.[name]) > 0
                    and tables.schema_id = 1
                    and Company.is_excluded = 0
                    )
                group by
                    right(tables.[name],len(tables.[name])-charindex('$',tables.[name])) collate database_default
            ) t
        left join
            (
                select
                    v.table_name,
                    v.altTS
                from
                    db_sys.consolidated v
            ) v
        on
            (
                t.[name] = v.[table_name]
            )
        where
            (
                t.modify_date > v.altTS
            or  v.[table_name] is null
            )

    end

else if (select 1 from db_sys.consolidated where table_name = @view_rebuild) = 1

    begin
    
        insert into @t (table_name, is_new, is_existing) values (@view_rebuild, 0, 1)

    end

--build / rebuild consolidated views
declare @table_name nvarchar(128), @_sql0 nvarchar(max), @_sql1 nvarchar(max)--, @_sql2 nvarchar(max)

if (object_id('tempdb..#ae01162ae9d84f31bc5d4b1566ff8999')) is not null drop table #ae01162ae9d84f31bc5d4b1566ff8999

select
    table_list.NAV_DB,
    table_list.table_name,
    column_list.column_name,
    column_id.column_id,
    case when _check.column_name is null then 0 else 1 end is_published
into 
    #ae01162ae9d84f31bc5d4b1566ff8999
from
    (
        select
            co.NAV_DB,
            iks.table_name
        from
            (select table_name from @t) iks, (select NAV_DB from db_sys.Company where is_excluded = 0) co
        where
            (
                concat(co.NAV_DB,'$',iks.table_name) in (select [name] collate database_default from sys.tables where schema_id = 1)
            )
    ) table_list
join
    (
        select distinct
            right(t.[name],len(t.[name])-charindex('$',t.[name])) collate database_default table_name,
            c.[name] collate database_default column_name
        from
            sys.columns c
        join
            sys.tables t
        on
            (
                c.object_id = t.object_id
            )
        where
            (
                t.schema_id = 1
            and charindex('$',t.[name]) > 0
            )
    ) column_list
on
    (
        table_list.table_name = column_list.table_name
    )
left join
    (
        select
            t.name collate database_default table_name,
            c.name collate database_default column_name
        from
            sys.tables t
        join
            sys.columns c
        on
            (
                t.object_id = c.object_id
            )
        where
            (
                t.schema_id = 1
            )
    ) _check
on
    (
        concat(table_list.NAV_DB,'$',table_list.table_name) = _check.table_name
    and column_list.column_name = _check.column_name
    )
cross apply
    (
        select top 1
            max(column_id) column_id
        from
            sys.tables t
        join
            sys.columns c
        on
            (
                t.object_id = c.object_id
            )
        where
            (
                right(t.[name],len(t.[name])-charindex('$',t.[name])) collate database_default = table_list.table_name
            and c.name collate database_default = column_list.column_name
            and t.schema_id != 24
            )
    ) column_id

if (object_id('tempdb..#b7ef678c9ae54cb691f16aa338b7e908')) is null

select
    *,
    dense_rank() over (order by table_name) table_key,
    dense_rank() over (partition by table_name order by column_id, column_name) column_key,
    dense_rank() over (partition by table_name order by NAV_DB) company_key
into
    #b7ef678c9ae54cb691f16aa338b7e908
from
    #ae01162ae9d84f31bc5d4b1566ff8999

declare [8b6c72c3-34aa-42ec-92e4-6d7efe16bb25] cursor for

with n as
    (

        select 
            t.company_key,
            t.table_name,
            t.table_key*1000+1 table_key,
            t.column_key,
            -5 sub_key,
            concat('create or alter view consolidated.[',t.table_name,']') _sql1
        from 
            #b7ef678c9ae54cb691f16aa338b7e908 t
        where
            (
                t.company_key = 1
            and t.column_key = 1
            )

        union all

        select 
            t.company_key,
            t.table_name,
            t.table_key*1000+1 table_key,
            t.column_key,
            -4 sub_key,
            concat(char(10),'as',char(10)) _sql1
        from 
            #b7ef678c9ae54cb691f16aa338b7e908 t
        where
            (
                t.company_key = 1
            and t.column_key = 1
            )

        union all

        select 
            t.company_key,
            t.table_name,
            t.table_key*1000+1 table_key,
            t.column_key,
            -3 sub_key,
            'select' _sql1
        from 
            #b7ef678c9ae54cb691f16aa338b7e908 t
        where
            (
                t.column_key = 1
            )

        union all

        select 
            t.company_key,
            t.table_name,
            t.table_key*1000+1 table_key,
            t.column_key,
            -2 sub_key,
            concat(char(9),'(select ID from db_sys.Company where NAV_DB = ''',NAV_DB,''') company_id,') _sql1
        from 
            #b7ef678c9ae54cb691f16aa338b7e908 t
        where
            (
                t.column_key = 1
            )

        union all

        select 
            t.company_key,
            t.table_name,
            t.table_key*1000+1 table_key,
            t.column_key,
            (t.company_key*10)+t.column_key sub_key,
            concat(char(9),case when t.is_published = 0 then 'null ' else '' end,'[',t.column_name,'],') _sql1
        from 
            #b7ef678c9ae54cb691f16aa338b7e908 t
        where
            t.column_key < (select max(column_key) from #b7ef678c9ae54cb691f16aa338b7e908 u where t.NAV_DB = u.NAV_DB and t.table_key = u.table_key)

        union all

        select 
            t.company_key,
            t.table_name,
            t.table_key*1000+1 table_key,
            t.column_key,
            (t.company_key*10)+t.column_key sub_key,
            concat(char(9),case when t.is_published = 0 then 'null ' else '' end,'[',t.column_name,']') _sql1
        from 
            #b7ef678c9ae54cb691f16aa338b7e908 t
        where
            t.column_key = (select max(column_key) from #b7ef678c9ae54cb691f16aa338b7e908 u where t.NAV_DB = u.NAV_DB and t.table_key = u.table_key)

        union all

        select 
            t.company_key,
            t.table_name,
            t.table_key*1000+1 table_key,
            t.column_key,
            (t.company_key*10)+t.column_key+1 sub_key,
            'from' _sql1
        from 
            #b7ef678c9ae54cb691f16aa338b7e908 t
        where
            t.column_key = (select max(column_key) from #b7ef678c9ae54cb691f16aa338b7e908 u where t.NAV_DB = u.NAV_DB and t.table_key = u.table_key)

        union all

        select 
            t.company_key,
            t.table_name,
            t.table_key*1000+1 table_key,
            t.column_key,
            (t.company_key*10)+t.column_key+2 sub_key,
            concat(char(9),'[dbo].[',t.NAV_DB,'$',t.table_name,'] t') _sql1
        from 
            #b7ef678c9ae54cb691f16aa338b7e908 t
        where
            t.column_key = (select max(column_key) from #b7ef678c9ae54cb691f16aa338b7e908 u where t.NAV_DB = u.NAV_DB and t.table_key = u.table_key)

        union all

        select 
            t.company_key,
            t.table_name,
            t.table_key*1000+1 table_key,
            t.column_key,
            (t.company_key*10)+t.column_key+3 sub_key,
            concat(char(10),'union all',char(10)) _sql2
        from 
            #b7ef678c9ae54cb691f16aa338b7e908 t
        where
            (
                t.column_key = (select max(column_key) from #b7ef678c9ae54cb691f16aa338b7e908 u where t.NAV_DB = u.NAV_DB and t.table_key = u.table_key)
            and t.company_key < (select max(company_key) from #b7ef678c9ae54cb691f16aa338b7e908 u where t.table_key = u.table_key)
            )

    )

    select
        table_name,
        string_agg(convert(nvarchar(max),_sql1),char(10)) within group (order by company_key, column_key, sub_key) _sql1
    from
        n
    group by
        table_name

open [8b6c72c3-34aa-42ec-92e4-6d7efe16bb25]

fetch next from [8b6c72c3-34aa-42ec-92e4-6d7efe16bb25] into @table_name, @_sql1

while @@fetch_status = 0

begin

select top 1 @_sql0 = object_definition from db_sys.objects_change_control where object_id = object_id(concat('consolidated.[',@table_name,']')) order by version_id desc

if left(@_sql1,5) = 'alter' if left(@_sql0,6) = 'create' set @_sql0 = concat('alter',right(@_sql0,len(@_sql0)-6))

if left(@_sql1,6) = 'create' or @_sql0 != @_sql1 exec (@_sql1)

fetch next from [8b6c72c3-34aa-42ec-92e4-6d7efe16bb25] into @table_name, @_sql1

end

close [8b6c72c3-34aa-42ec-92e4-6d7efe16bb25]
deallocate [8b6c72c3-34aa-42ec-92e4-6d7efe16bb25]

insert into db_sys.consolidated (table_name) select table_name from @t where is_new = 1

update
    h
set
    h.altTS = getutcdate()
from
    db_sys.consolidated h
join
    @t t
on
    (
        h.table_name = t.table_name
    )
where
    (
        t.is_existing = 1
    )