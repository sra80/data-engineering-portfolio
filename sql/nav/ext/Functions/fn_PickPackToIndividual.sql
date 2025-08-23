



CREATE function [ext].[fn_PickPackToIndividual]
	(
		@whseNo nvarchar(50),
		@sourceNo nvarchar(50)

	)

returns int

as

begin

declare @ID int



select
	@ID = 1
from
	(
	select distinct
		 wsl.[No_]
		,wsl.[Source No_] 
		,sum(wsl.[Quantity]) over (partition by  wsl.[No_], wsl.[Source No_]) s
	 from
		[dbo].[UK$Warehouse Shipment Line] wsl
	join
		[dbo].[UK$Warehouse Shipment Header] wsh	
	on
		(
			wsl.[No_] = wsh.[No_]
		)
	where
		wsh.[Whse_ Shipment Type] = 2
	
	union

	select distinct
		 pwsl.[No_]
		,pwsl.[Source No_] 
		,sum(pwsl.[Quantity]) over (partition by  pwsl.[No_], pwsl.[Source No_]) s
	from
		[ext].[Posted_Whse_Line] pwsl
	join
		[ext].[Posted_Whse_Header] pwsh	
	on
		pwsl.[No_] = pwsh.[No_]
	where
		pwsh.[Whse_ Shipment Type] = 2
	) x
join
	(
	select distinct
		 [Whse No]
		,[Source No_]
		,[Item No_]
	from
		[ext].[Warehouse_Shipments]
	) y
on
	(
		x.[No_] = y.[Whse No]
	and x.[Source No_] = y.[Source No_]
	)
join
		(
			select
				 i.[No_]
				,i.[Box Type]
			from
				[dbo].[UK$Item] i
			join
				[dbo].[UK$Box Type] bt
			on
				(
					i.[Box Type] = bt.[Code]
				and bt.[Pick as Set] = 0
				)
			where
				i.[Packaging Type] = 'LARGELETTER'
		) i
	on
		(
			y.[Item No_] = i.[No_]
		)	
where
	x.s = 1
and x.[No_] = @whseNo
and x.[Source No_] = @sourceNo

if @ID is null

select @ID = 0

return @ID

end
GO
