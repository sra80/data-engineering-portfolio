create function marketing.fn_csh_opt_source_lookup
    (
        @opt_source nvarchar(255)
    )

returns int

begin

declare @opt_source_id int

select @opt_source_id = id from marketing.csh_opt_source where opt_source = @opt_source

if @opt_source_id is null set @opt_source_id = -1

return @opt_source_id

end
GO
