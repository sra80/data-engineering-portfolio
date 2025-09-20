create or alter procedure [db_sys].[sp_set_insight_permissions]

as

set nocount on

declare @table_list table (_table nvarchar(64))

declare @permissions table ([Owner] nvarchar(max), [Object] nvarchar(max), [Grantee] nvarchar(max), [Grantor] nvarchar(max), [ProtectType] nvarchar(max), [Action] nvarchar(max), [Column] nvarchar(max))

insert into @table_list (_table)
values
    ('Purch_ Inv_ Header'),
    ('Purch_ Inv_ Line'),
    ('Purch_ Cr_ Memo Hdr_'),
    ('Purch_ Cr_ Memo Line'),
    ('Vendor Ledger Entry'),
    ('G_L Entry'),
    ('General Ledger Setup'),
    ('G_L Account'),
    ('Item'),
    ('Manufacturer'),
    ('Item Category'),
    ('Vendor'),
    ('Payment Terms'),
    ('Dimension Value'),
    ('Fixed Asset'),
    ('Job'),
    ('Resource'),
    ('Item Charge'),
    ('Dimension Set Entry')

declare @sql nvarchar(max) = ''

declare @user nvarchar(64) = '_insight'

insert into @permissions exec sp_helprotect

select
    @sql += sql_command
from
    (
        select
            concat('grant select on [dbo].[',concat(c.NAV_DB,'$',t._table),'] to [',@user,']',char(10)) collate database_default sql_command
        from
            @table_list t
        cross apply
            db_sys.Company c
        left join
            (
                select
                    [Object]
                from 
                    @permissions 
                where 
                    (
                        [Object] like '%$%'
                    and [Grantee] = @user
                    and [ProtectType] = 'Grant'
                    and [Action] = 'Select'
                    )
            ) p
        on
            (
                concat(c.NAV_DB,'$',t._table) = p.[Object]
            )
        where
            (
                c.is_insightInc = 1
            and p.[Object] is null
            )

        union

        select
            concat('grant select on [dbo].[',s._full,'] to [',@user,']',char(10))
        from
            @table_list t
        join
            (select left(name collate database_default,charindex('$',name)-1) _company, right(name collate database_default,len(name)-charindex('$',name)) _table, name _full from sys.tables where charindex('$',name) > 0 and create_date >= (select last_processed from db_sys.procedure_schedule where procedureName = 'db_sys.sp_set_insight_permissions')) s
        on
            (
                t._table = s._table
            )
        join
            db_sys.Company c
        on
            (
                s._company = c.NAV_DB 
            and c.is_insightInc = 1
            )
    ) permission_checks

exec (@sql)
GO
