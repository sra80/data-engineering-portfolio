create or alter procedure [db_sys].[recreate_missing_indexes]
 
 as
 
 /*
  Description:		Handles recreation of indexes in the event of a publication reinitialization.
  Project:			112
  Creator:			Shaun Edwards(SE)
  Copyright:			CompanyX Limited, 2021
 MOD	DATE	INITS	COMMENTS
 00  210423  SE      Created
 01  210930  SE      update db_sys.index_info where tables no longer exist added 30/09/2021 @ 0944
 02  211215  SE      Add error handling rather than blocking the whole procedure when a single failure occurs. Introduction of db_sys.recreate_missing_indexes_log
 03  220705  SE      Fix to info for deleted indexes "Deleted as table not longer exists." corrected to "Deleted as table no longer exists."
 04  220706  SE      Variable @error_message changed fromm nvarchar(36) to nvarchar(max)
 05  231004  SE      Add additional clause to check if index may exist after cursor is established
 */
 
 set nocount on
 
 --update db_sys.index_info where tables no longer exist added 30/09/2021 @ 0944
 update 
     i
 set
     info = info + case when right(info,1) = '.' then '' else '.' end + ' Deleted as table no longer exists.',
     deletedBy = lower(system_user),
     deletedDate = getutcdate()
 from
     db_sys.index_info i
 cross apply
     (
         select 
             [1],
             [2]
         from 
             (
                 select 
                     replace(replace(value,'[',''),']','') value, row_number() over (order by (value)) r 
                 from 
                     string_split(i.tableName,'.')
             ) j
         pivot
             (
                 max(value)
             for r in ([1],[2])
             ) p
     ) x
 where
     i.deletedDate is null
 and [1] collate database_default not in (select name from sys.tables t)
 and [2] collate database_default not in (select name from sys.tables t)
 
 update db_sys.index_info set indexName = replace(replace(indexName,'[',''),']','') where PATINDEX('IX__[A-Z0-9][A-Z0-9][A-Z0-9]',indexName) = 0
 
 declare @indexScript nvarchar(max), @indexName nvarchar(64), @error_message nvarchar(max), @auditLog_ID int
 
 select @auditLog_ID = a.ID from db_sys.auditLog a join db_sys.procedure_schedule s on upper(a.eventDetail) = upper(convert(nvarchar(36),s.place_holder)) where s.procedureName = 'db_sys.recreate_missing_indexes' 
 
 declare i cursor for select h.script, h.indexName from db_sys.index_info h left join sys.indexes i on h.indexName = i.[name] collate database_default where i.name is null and h.deletedBy is null and h.errorBlock = 0
 
 open i
 
 fetch next from i into @indexScript, @indexName
 
 while @@FETCH_STATUS = 0
 
 begin
 
     begin try

        if (select name from sys.indexes where name = @indexName) is null --

            begin
 
                exec (@indexScript)
        
                insert into db_sys.recreate_missing_indexes_log (indexName) values (@indexName)

            end
 
     end try
 
     begin catch
 
         update db_sys.index_info set errorBlock = 1 where indexName = @indexName
 
         set @error_message = 'The attempt to create index <b>' + @indexName + '</b> has failed, with error <i>'
 
         set @error_message += error_message()
 
         set @error_message += '</i><p>Please check the index script in table db_sys.index_info and reset the value of errorBlock back to 0.'
 
         insert into db_sys.procedure_schedule_errorLog (procedureName, auditLog_ID, errorLine, errorMessage) values ('db_sys.recreate_missing_indexes',isnull(@auditLog_ID,0),error_line(),@error_message)
 
     end catch
 
 fetch next from i into @indexScript, @indexName
 
 end
 
 close i
 deallocate i
GO
