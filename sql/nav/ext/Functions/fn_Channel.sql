
CREATE function [ext].[fn_Channel]
    (
        @company_id int,
        @Channel_Code nvarchar(10)
    )

returns int

as

begin

declare @channel_id int

select
    @channel_id = ID
from
    ext.Channel
where
    (
        company_id = @company_id
    and Channel_Code = @Channel_Code
    )

if @channel_id is null select top 1 @channel_id = ID from ext.Channel where company_id = @company_id and Channel_Code = 'PHONE'

if @channel_id is null select top 1 @channel_id = ID from ext.Channel where company_id = @company_id and Group_Code = 3

return @channel_id

end
GO
