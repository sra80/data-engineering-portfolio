create or alter procedure ext.sp_Customer_Acorn

as

set nocount on

merge ext.Customer_Acorn t
using 
	(
		select
			c.CUST_REF cus_code,
			c.AcornType acorn_type,
			getutcdate() addedTSUTC,
			getutcdate() updatedTSUTC
		from 
			scv.CUSTOMER c 
		cross apply 
			(
				select top 1
					CUST_REF
				from 
					scv.CUSTOMER x
				where 
					(
						x.AcornType > 0
					and c.CUST_REF = x.CUST_REF
					and c.SCV_ID = x.SCV_ID
					)
				order by
					SCV_ID desc
			) y
	) s
on
	(
		t.cus_code = s.cus_code collate database_default
	)
when not matched by target then
	insert (cus_code, acorn_type, addedTSUTC, updatedTSUTC)
	values (s.cus_code, s.acorn_type, s.addedTSUTC, s.updatedTSUTC)
when matched and s.updatedTSUTC > t.updatedTSUTC then update set
	t.acorn_type = s.acorn_type,
	t.updatedTSUTC = s.updatedTSUTC;
GO