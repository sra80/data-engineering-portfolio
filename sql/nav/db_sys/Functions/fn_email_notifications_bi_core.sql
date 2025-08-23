-- fix where blank @email_add_list counts as 1 email add

CREATE function db_sys.fn_email_notifications_bi_core
    (
        @email_add_list nvarchar(max) = ''
    )

returns @t table (new_list nvarchar(max), bi_core bit, email_count int)

as

begin

declare @string_out nvarchar(max) = '', @email_count int = 0

select @string_out += case when len(@string_out) = 0 then '' else ';' end + value, @email_count += 1 from string_split(nullif(@email_add_list,''),';') where value not like '%bi_reply%'

insert into @t (new_list, bi_core, email_count) values (@string_out, case when @email_add_list like '%bi_reply%' then 1 else 0 end, @email_count)

return

end
GO
