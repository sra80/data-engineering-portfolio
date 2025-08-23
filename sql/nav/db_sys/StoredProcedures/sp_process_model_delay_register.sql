create or alter procedure db_sys.sp_process_model_delay_register

as

set nocount on

declare
    @report_delays_after int = 60, --set this in minutes
    @now_utc datetime2(0) = dateadd(second,-datepart(second,getutcdate()),getutcdate()),
    @model_name nvarchar(32),
    @process_active bit,
    @process bit,
    @template_message nvarchar(max),
    @delay_min int,
    @delay_string nvarchar(32),
    @delay_post_ts datetime2(3),
    @queued_post_ts datetime2(3),
    @processing_post_ts datetime2(3),
    @back_on_track_ts datetime2(3),
    @message nvarchar(max),
    @send_message bit,
    @subject nvarchar(255),
    @place_holder uniqueidentifier

declare
    @gmt_hour int = datepart(hour,db_sys.fn_datetime_utc_to_gmt(@now_utc))

--add new models to db_sys.process_model_delay_register - provide generic template message
insert into db_sys.process_model_delay_register (model_name, template_message)
select
    pm.model_name,
    'This will affect some of the reports in Power BI'
from
    db_sys.process_model pm
left join
    db_sys.process_model_delay_register dr
on
    (
        pm.model_name = dr.model_name
    )
where
    (
        dr.model_name is null
    )

--reset for new day
update 
    db_sys.process_model_delay_register
set
    delay_string = null,
    delay_post_ts = null,
    queued_post_ts = null,
    processing_post_ts = null,
    back_on_track_ts = null,
    place_holder = null
where
    delay_post_ts < convert(date,getutcdate())


declare @list table
    (
        model_name nvarchar(32),
        process_active bit,
        process bit,
        template_message nvarchar(max),
        delay_min int,
        delay_string nvarchar(32),
        delay_post_ts datetime2(3),
        queued_post_ts datetime2(3),
        processing_post_ts datetime2(3),
        back_on_track_ts datetime2(3),
        place_holder uniqueidentifier
    )

insert into @list (model_name, process_active, process, delay_string, delay_min, template_message, delay_post_ts, queued_post_ts, processing_post_ts, back_on_track_ts, place_holder)
select
    pm.model_name,
    pm.process_active,
    x.process,
    x.delay_string,
    isnull(x.delay_min,0),
    dr.template_message,
    dr.delay_post_ts,
    dr.queued_post_ts,
    dr.processing_post_ts,
    dr.back_on_track_ts,
    dr.place_holder
from
    db_sys.process_model pm
join
    db_sys.process_model_delay_register dr
on
    (
        pm.model_name = dr.model_name
    )
outer apply
    (
        select top 1
            pmp.process,
            db_sys.fn_datediff_string
                (
                    db_sys.fn_set_process_next_due
                        (
                            pmp.frequency_unit,
                            pmp.frequency_value,
                            pmp.last_processed,
                            pm.start_month,
                            pm.start_day,
                            pm.start_dow,
                            pm.start_hour,
                            pm.start_minute,
                            pm.end_month,
                            pm.end_day,
                            pm.end_dow,
                            pm.end_hour,
                            pm.end_minute,
                            @now_utc,
                            0
                        ),
                    @now_utc,
                    5
                ) delay_string,
            datediff
                (
                    minute,
                    db_sys.fn_set_process_next_due
                        (
                            pmp.frequency_unit,
                            pmp.frequency_value,
                            pmp.last_processed,
                            pm.start_month,
                            pm.start_day,
                            pm.start_dow,
                            pm.start_hour,
                            pm.start_minute,
                            pm.end_month,
                            pm.end_day,
                            pm.end_dow,
                            pm.end_hour,
                            pm.end_minute,
                            @now_utc,
                            0
                        ),
                    @now_utc
                ) delay_min
        from
            (
                select
                    model_name,
                    process,
                    frequency_unit,
                    frequency_value,
                    (select max(x.x) from (values (last_processed),(last_offset_ts)) as x(x)) last_processed
                from
                    db_sys.process_model_partitions) pmp
        where
            (
                pm.model_name = pmp.model_name
            and datediff
                (
                    minute,
                    db_sys.fn_set_process_next_due
                        (
                            pmp.frequency_unit,
                            pmp.frequency_value,
                            pmp.last_processed,
                            pm.start_month,
                            pm.start_day,
                            pm.start_dow,
                            pm.start_hour,
                            pm.start_minute,
                            pm.end_month,
                            pm.end_day,
                            pm.end_dow,
                            pm.end_hour,
                            pm.end_minute,
                            @now_utc,
                            0
                        ),
                    @now_utc
                ) >= @report_delays_after
            and datediff
                (
                    day,
                    db_sys.fn_set_process_next_due
                        (
                            pmp.frequency_unit,
                            pmp.frequency_value,
                            pmp.last_processed,
                            pm.start_month,
                            pm.start_day,
                            pm.start_dow,
                            pm.start_hour,
                            pm.start_minute,
                            pm.end_month,
                            pm.end_day,
                            pm.end_dow,
                            pm.end_hour,
                            pm.end_minute,
                            @now_utc,
                            0
                        ),
                    @now_utc
                ) < 30 --prevents cases where schedule is changed from being reported as delayed
            )
        order by
            3 desc

    ) x
where
    (
        pm.disable_process = 0
    )

while (select isnull(sum(1),0) from @list) > 0

begin /*95ec*/

select top 1
    @model_name = model_name,
    @process_active = process_active,
    @process = process,
    @delay_string = delay_string,
    @delay_min = delay_min,
    @template_message = template_message,
    @delay_post_ts = delay_post_ts,
    @queued_post_ts = queued_post_ts,
    @processing_post_ts = processing_post_ts,
    @back_on_track_ts = back_on_track_ts,
    @message = null,
    @send_message = 0,
    @subject = concat('Delay processing data model ',model_name),
    @place_holder = place_holder
from
    @list

--delayed
if @delay_min > 0

    begin /*4e99*/

        set @send_message = 1

        if @delay_post_ts is null and @gmt_hour >= 6 and @gmt_hour <= 20
        
            begin /*e493*/
            
                begin /*e37e*/

                    set @place_holder = newid()
                
                    set @message = concat('The refresh of the <b>',@model_name,'</b> data model is ',@delay_string,' behind schedule')

                    update db_sys.process_model_delay_register set delay_post_ts = getutcdate(), delay_string = @delay_string, back_on_track_ts = null, place_holder = @place_holder where model_name = @model_name
                    
                end /*e37e*/

                if @process_active = 1 
                
                    begin /*46de*/
                    
                        set @message += ', however it is currently being processed'

                        update db_sys.process_model_delay_register set processing_post_ts = getutcdate() where model_name = @model_name
                        
                    end /*46de*/

                if @process_active = 0 and @process = 1 
                
                    begin /*e8f9*/
                    
                        set @message += ', however it is currently queued for processing'

                        update db_sys.process_model_delay_register set queued_post_ts = getutcdate() where model_name = @model_name
                        
                    end /*e8f9*/

                set @message += concat('. ',@template_message)

                if charindex('.',right(@message,1)) = 0 set @message += '.'

            end /*e493*/

        if @delay_post_ts is not null and @place_holder is not null

            begin /*93f4*/

                if @processing_post_ts is null and @queued_post_ts is null and @process_active = 0 and @process = 1 
                
                    begin /*cd7f*/
                    
                        set @message = concat('The ',@model_name,' model is now queued for processing.')

                        update db_sys.process_model_delay_register set queued_post_ts = getutcdate() where model_name = @model_name

                    end /*cd7f*/

                if @processing_post_ts is null and @process_active = 1 
                
                    begin /*230f*/
                    
                        set @message = concat('The ',@model_name,' model is now processing.')

                        update db_sys.process_model_delay_register set processing_post_ts = getutcdate() where model_name = @model_name

                    end /*230f*/

            end /*93f4*/

    end /*4e99*/

--no longer delayed
if @delay_min = 0 and @delay_post_ts is not null and @back_on_track_ts is null

    begin /*98d0*/

    set @send_message = 1

    set @message = concat('The ',@model_name,' model has just completed processing and is no longer behind schedule.')

    update db_sys.process_model_delay_register set delay_string = null, delay_post_ts = null, queued_post_ts = null, processing_post_ts = null, back_on_track_ts = getutcdate(), place_holder = null where model_name = @model_name

    end /*98d0*/

if @send_message = 1

    begin /*340a*/

    exec db_sys.sp_email_notifications
        @subject = @subject,
        @bodyIntro = @message,
        @is_team_alert = 1,
        @tnc_id = 0,
        @place_holder = @place_holder

    end /*340a*/

delete from @list where model_name = @model_name

end /*95ec*/