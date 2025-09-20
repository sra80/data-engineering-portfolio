CREATE function [db_sys].[fomonth]
	(
		@date date
	)

returns date

with schemabinding

as

begin

set @date = datefromparts(year(@date),month(@date),1)

return @date

end
GO
