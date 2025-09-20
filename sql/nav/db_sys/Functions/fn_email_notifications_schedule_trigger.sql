CREATE function [db_sys].[fn_email_notifications_schedule_trigger]
    (
        @ID int,
        @quoted bit = 1
    )

returns @t table (_row int identity(0,1), _definition nvarchar(max))

as

begin

if @quoted = 1

    begin

    insert into @t (_definition)
    select value from (select replace(email_trigger,'''','''''') email_trigger from db_sys.email_notifications_schedule where ID = @ID) x cross apply string_split(email_trigger,char(10)) y

    update @t set _definition = concat('''',_definition) where _row = 0

    update @t set _definition = concat(_definition,'''') where _row = (select max(_row) from @t)

    end

else

insert into @t (_definition)
select value from (select email_trigger from db_sys.email_notifications_schedule where ID = @ID) x cross apply string_split(email_trigger,char(10)) y

return

end
GO
