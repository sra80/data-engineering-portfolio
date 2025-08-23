create procedure db_sys.sp_nav_user_sessions

as

declare @auditLog_ID int

select @auditLog_ID = ID from db_sys.auditLog where try_convert(uniqueidentifier,eventDetail) = (select place_holder from db_sys.procedure_schedule where procedureName = replace(replace('db_sys.sp_nav_user_sessions','[',''),']',''))

if @auditLog_ID is null set @auditLog_ID = next value for db_sys.sq_nav_user_sessions

insert into db_sys.nav_user_sessions (auditLog_ID, UserID, sessionCount)
select @auditLog_ID, [User ID], count(1) from dbo.[Active Session] (nolock) where left([User ID],10)='CompanyX' group by [User ID]
GO
