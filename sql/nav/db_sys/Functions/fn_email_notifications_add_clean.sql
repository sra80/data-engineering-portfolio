CREATE function db_sys.fn_email_notifications_add_clean
	(
		@email_adds nvarchar(max)
	)

returns nvarchar(max)

as

begin

declare @email_add_clean nvarchar(max)

;with n as
	(
		select value e from string_split(@email_adds,';')
	)

select @email_add_clean = coalesce(@email_add_clean + ';','') + replace(right(e,LEN(e)-CHARINDEX('<',e)),'>','') from n

return @email_add_clean

end
GO
