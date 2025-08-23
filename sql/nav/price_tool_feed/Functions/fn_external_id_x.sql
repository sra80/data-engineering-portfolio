create or alter function price_tool_feed.fn_external_id_x
    (
        @external_id_list nvarchar(max),
        @splitter nvarchar(1) = '|',
        @index int = 1
    )

returns uniqueidentifier

as

begin

    declare @exernal_id uniqueidentifier

    select
        @exernal_id = try_convert(uniqueidentifier,value)      
    from
        string_split(@external_id_list,@splitter,1) x
    where
        (
            ordinal = @index
        )

return @exernal_id

end