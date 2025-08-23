
create or alter view [db_sys].[vw_email_notifications]

as

select
	 ID
	,email_to.new_list email_to
	,email_cc.new_list email_cc
	,email_subject
	,REPLACE
		(
			 email_body
			,'***timeofday***'
			,case 
				when t.gg_hour < 12 then 'morning'
				when t.gg_hour >= 12 and t.gg_hour < 18 then 'afternoon'
				else 'evening'
			end
		) email_body
	,email_importance
    ,case when email_to.bi_core = 1 or email_cc.bi_core = 1 then 1 else 0 end bi_core
    ,email_to.email_count + email_cc.email_count email_count
from
	db_sys.email_notifications
cross apply
	(
		select 
			datepart(hour,switchoffset(getutcdate(),current_utc_offset)) gg_hour 
		from 
			sys.time_zone_info where name = 'GMT Standard Time'
	) t
cross apply
    db_sys.fn_email_notifications_bi_core(db_sys.fn_email_notifications_add_clean(email_to)) email_to
cross apply
    db_sys.fn_email_notifications_bi_core(db_sys.fn_email_notifications_add_clean(email_cc)) email_cc
where
	email_sent is null
and auditLog_ID > -2
GO
