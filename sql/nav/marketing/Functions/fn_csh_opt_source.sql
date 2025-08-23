CREATE function [marketing].[fn_csh_opt_source]
    (
       @string nvarchar(255)
    )

--strips [Web Page URL] in [dbo].[UK$Customer Preferences Log] 

-- for end character, add reverse to @string to detect last instance of the character list
-- for end character, earliest found instance wins between 2 patterns

returns nvarchar(255)

as

begin

declare @start nvarchar(10) = '%[:/]%', @end0 nvarchar(10) = '%[,%]%', @end1 nvarchar(10) = '%[?]%', @end nvarchar(10)

if patindex(@end0,reverse(@string)) > patindex(@end1,reverse(@string)) set @end = @end0 else set @end = @end1

if patindex(@start,@string) > 0 and len(@string)-patindex(@end,reverse(@string)) > patindex(@start,@string)

set @string = nullif(lower(substring(@string,patindex(@start,@string)+1,len(@string)-patindex(@end,reverse(@string))-patindex(@start,@string))),'')

return @string

end
GO
