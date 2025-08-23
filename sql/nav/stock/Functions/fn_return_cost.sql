create function stock.fn_return_cost
	(
		@company_id int,
        @key_location nvarchar(10),
		@key_sku nvarchar(32)
	)

returns @t table (unit_cost_actual float, unit_cost_expected float)

as

begin

if @company_id = 1

insert into @t (unit_cost_actual, unit_cost_expected)
select 
	 ve.cost_actual/ile.Quantity unit_cost_actual
	,ve.cost_expected/ile.Quantity unit_cost_expected
from
	(
		select
			max([Entry No_]) [Entry No_]
		from
			[dbo].[UK$Item Ledger Entry]
		where
			(
				[Location Code] = @key_location
			and [Item No_] = @key_sku
			and [Entry Type] = 1
			)
		) base
join
	[dbo].[UK$Item Ledger Entry] ile
on
	(
		base.[Entry No_] = ile.[Entry No_]
	)
cross apply 
	(
		select
			 sum([Cost Amount (Actual)]) cost_actual
			,sum([Cost Amount (Expected)]) cost_expected
		from
			[dbo].[UK$Value Entry]
		where
			[Item Ledger Entry No_] = base.[Entry No_]
	) ve

if @company_id = 4

insert into @t (unit_cost_actual, unit_cost_expected)
select 
	 ve.cost_actual/ile.Quantity unit_cost_actual
	,ve.cost_expected/ile.Quantity unit_cost_expected
from
	(
		select
			max([Entry No_]) [Entry No_]
		from
			[dbo].[NL$Item Ledger Entry]
		where
			(
				[Location Code] = @key_location
			and [Item No_] = @key_sku
			and [Entry Type] = 1
			)
		) base
join
	[dbo].[NL$Item Ledger Entry] ile
on
	(
		base.[Entry No_] = ile.[Entry No_]
	)
cross apply 
	(
		select
			 sum([Cost Amount (Actual)]) cost_actual
			,sum([Cost Amount (Expected)]) cost_expected
		from
			[dbo].[NL$Value Entry]
		where
			[Item Ledger Entry No_] = base.[Entry No_]
	) ve

if @company_id = 5

insert into @t (unit_cost_actual, unit_cost_expected)
select 
	 ve.cost_actual/ile.Quantity unit_cost_actual
	,ve.cost_expected/ile.Quantity unit_cost_expected
from
	(
		select
			max([Entry No_]) [Entry No_]
		from
			[dbo].[NZ$Item Ledger Entry]
		where
			(
				[Location Code] = @key_location
			and [Item No_] = @key_sku
			and [Entry Type] = 1
			)
		) base
join
	[dbo].[NZ$Item Ledger Entry] ile
on
	(
		base.[Entry No_] = ile.[Entry No_]
	)
cross apply 
	(
		select
			 sum([Cost Amount (Actual)]) cost_actual
			,sum([Cost Amount (Expected)]) cost_expected
		from
			[dbo].[NZ$Value Entry]
		where
			[Item Ledger Entry No_] = base.[Entry No_]
	) ve

if @company_id = 6

insert into @t (unit_cost_actual, unit_cost_expected)
select 
	 ve.cost_actual/ile.Quantity unit_cost_actual
	,ve.cost_expected/ile.Quantity unit_cost_expected
from
	(
		select
			max([Entry No_]) [Entry No_]
		from
			[dbo].[IE$Item Ledger Entry]
		where
			(
				[Location Code] = @key_location
			and [Item No_] = @key_sku
			and [Entry Type] = 1
			)
		) base
join
	[dbo].[IE$Item Ledger Entry] ile
on
	(
		base.[Entry No_] = ile.[Entry No_]
	)
cross apply 
	(
		select
			 sum([Cost Amount (Actual)]) cost_actual
			,sum([Cost Amount (Expected)]) cost_expected
		from
			[dbo].[IE$Value Entry]
		where
			[Item Ledger Entry No_] = base.[Entry No_]
	) ve

return

end
GO
