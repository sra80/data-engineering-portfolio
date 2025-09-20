create or alter procedure db_sys.sp_elasticjob_errorlog

as

declare
    @job_execution_id uniqueidentifier,
    @job_name nvarchar(128),
    @last_message nvarchar(max)

declare [cf167141-b0c1-4bbf-b06a-41e60b7e8713] cursor for

select
    je.job_execution_id,
    string_agg(je.job_name,','),
    string_agg(je.last_message,replicate(char(10),2))
from
    jobs.job_executions je
left join
    db_sys.elasticjob_errorlog el
on
    (
    je.job_execution_id = el.job_execution_id
    )
where 
    (
        je.target_database_name = db_name()
    and je.lifecycle = 'Failed'
    and el.job_execution_id is null
    )
group by
    je.job_execution_id

open [cf167141-b0c1-4bbf-b06a-41e60b7e8713]

fetch next from [cf167141-b0c1-4bbf-b06a-41e60b7e8713] into @job_execution_id, @job_name, @last_message

while @@fetch_status = 0

begin

set @job_name = concat('Error with Elastic Job ',@job_name)

exec db_sys.sp_email_notifications
    @subject = @job_name,
    @bodyIntro = @last_message,
    @is_team_alert = 1,
    @tnc_id = 6

insert into db_sys.elasticjob_errorlog (job_execution_id) values (@job_execution_id)

fetch next from [cf167141-b0c1-4bbf-b06a-41e60b7e8713] into @job_execution_id, @job_name, @last_message

end

close [cf167141-b0c1-4bbf-b06a-41e60b7e8713]
deallocate [cf167141-b0c1-4bbf-b06a-41e60b7e8713]
