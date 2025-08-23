
CREATE function [ext].[fn_doc_prefix]
	(
		@docNo nvarchar(32)
	)

returns nvarchar(32)

as

begin

if PATINDEX('[A-Z]%',@docNo) > 0 and PATINDEX('%[^A-Z]%',@docNo) > 0 set @docNo = left(@docNo,PATINDEX('%[^A-Z]%',@docNo)-1)

return @docNo

end
GO
