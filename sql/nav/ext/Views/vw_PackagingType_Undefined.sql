


CREATE   view [ext].[vw_PackagingType_Undefined]



as



select

	[keyBox],

	[box_type]

from

	[ext].[Packaging_Type] p

join

	[db_sys].[email_notifications_schedule] ens

on

	(

		p.[insertedTSUTC] >= ens.[last_processed]

	and ens.[ID] = 32

	)

where

	(

		p.[Packaging Type] = 'Undefined'

	)
GO
