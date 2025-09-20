create or alter function db_sys.fn_num_ordinal
    (
        @num int
    )

returns nvarchar(32)

as

begin

declare @oridinal nvarchar(32)

if 

    @num % 100 in (11,12,13) set @oridinal = concat(@num,'th')

else if 

    @num % 10 = 1 set @oridinal = concat(@num,'st')

else if 

    @num % 10 = 2 set @oridinal = concat(@num,'nd')

else if 

    @num % 10 = 3 set @oridinal = concat(@num,'rd')

else 

    set @oridinal = concat(@num,'th')

return @oridinal

end