create or alter function db_sys.fn_user_is_uniqueidentifier
    (
        @user nvarchar(255)
    )

returns bit

as

begin

declare @is_uniqueidentifier bit = 0

select top 1
    @is_uniqueidentifier = case when try_convert(uniqueidentifier,value) is null then 0 else 1 end
from
    string_split(@user,'@')

return @is_uniqueidentifier

end