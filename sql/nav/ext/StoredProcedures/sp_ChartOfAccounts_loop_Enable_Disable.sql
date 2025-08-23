


CREATE procedure [ext].[sp_ChartOfAccounts_loop_Enable_Disable]

as

declare @result bit


select
	@result = sum(r)
from
	(
		select 
			1 r
		from
			[dbo].[UK$General Ledger Setup]
		where
			datediff(month,[Allow Posting From],getdate()) > 0

		union all

		select
			1
		from
			[dbo].[CE$General Ledger Setup]
		where
			datediff(month,[Allow Posting From],getdate()) > 0

		union all

		select
			1
		from
			[dbo].[NL$General Ledger Setup]
		where
			datediff(month,[Allow Posting From],getdate()) > 0

		union all

		select
			1
		from
			[dbo].[NZ$General Ledger Setup]
		where
			datediff(month,[Allow Posting From],getdate()) > 0

		union all

		select
			1
		from
			[dbo].[IE$General Ledger Setup]
		where
			datediff(month,[Allow Posting From],getdate()) > 0

		union all

		select
			1
		from
			[dbo].[QC$General Ledger Setup]
		where
			datediff(month,[Allow Posting From],getdate()) > 0
	) x
	

if @result >= 1 


update [db_sys].[process_model] set disable_process = 0 where model_name = 'Finance_ChartOfAccounts' and disable_process = 1 and error_count = 0

else update [db_sys].[process_model] set disable_process = 1 where model_name = 'Finance_ChartOfAccounts' and disable_process = 0
GO
