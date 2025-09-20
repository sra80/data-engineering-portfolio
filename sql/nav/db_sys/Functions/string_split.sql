create function db_sys.string_split
    (
        @string nvarchar(max),
        @char nvarchar(1)
    )

returns @r table ([1] nvarchar(max),[2] nvarchar(max),[3] nvarchar(max),[4] nvarchar(max),[5] nvarchar(max),[6] nvarchar(max),[7] nvarchar(max),[8] nvarchar(max),[9] nvarchar(max),[10] nvarchar(max))

as

begin

declare @t table (i int identity, v nvarchar(max))

insert into @t (v)
select value from string_split(@string,@char)

insert into @r ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])
select
    [1],[2],[3],[4],[5],[6],[7],[8],[9],[10]
from
    @t t
pivot
    (
        max(v) for i in ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])
    ) p

return

end
GO
