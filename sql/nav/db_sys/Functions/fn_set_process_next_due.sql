create or alter function db_sys.fn_set_process_next_due
	(
		@frequency_unit nvarchar(8),
		@frequency_value int,
		@last_processed datetime2(0),
		@start_month int,
		@start_day int,
		@start_dow int,
		@start_hour int,
		@start_minute int,
		@end_month int,
		@end_day int,
		@end_dow int,
		@end_hour int,
		@end_minute int,
        @utcdatetime datetime2(0) = null,
        @set_overdue_now bit = 1
	)

returns datetime2(0)

as

begin

declare @next_due datetime2(0), @ds_offset int = datediff(hour,db_sys.fn_datetime_utc_to_gmt(default),getutcdate()), @ds_offset_start int

if @ds_offset = -1

    begin
        
        set @ds_offset_start = 23

        set @start_hour = @start_hour + @ds_offset

    end

if @utcdatetime is null set @utcdatetime = getutcdate()

if @frequency_unit = 'minute'

    begin

        select top 1
            @next_due = x.next_due
        from
            (
                select 
                    iteration.next_due,
                    iteration.process_flag,
                    iteration.iteration
                from
                    (
                        select
                            h_i.iteration,
                            dateadd(minute,h_i.iteration,(select min(x.x) from (values (@last_processed),(@utcdatetime)) as x(x))) next_due,
                            db_sys.fn_set_process_flag
                                (
                                    @frequency_unit,
                                    @frequency_value,
                                    @last_processed,
                                    @start_month,
                                    @start_day,
                                    @start_dow,
                                    @start_hour,
                                    @start_minute,
                                    @end_month,
                                    @end_day,
                                    @end_dow,
                                    @end_hour,
                                    @end_minute,
                                    dateadd(minute,h_i.iteration,(select min(x.x) from (values (@last_processed),(@utcdatetime)) as x(x)))
                                ) process_flag
                        from
                            db_sys.iteration h_i
                        where
                            (
                                h_i.iteration < 10000
                            )
                    ) iteration
            ) x
        where
            x.process_flag = 1
        order by
            x.iteration

        set @next_due = dateadd(minute,-datepart(minute,@next_due)%5,dateadd(second,-datepart(second,@next_due),@next_due))

    end

if @frequency_unit = 'hour'

    begin

        select top 1
            @next_due = x.next_due
        from
            (
                select 
                    iteration.next_due,
                    iteration.process_flag,
                    iteration.iteration
                from
                    (
                        select
                            h_i.iteration,
                            dateadd(hour,h_i.iteration,(select min(x.x) from (values (@last_processed),(@utcdatetime)) as x(x))) next_due,
                            db_sys.fn_set_process_flag
                                (
                                    @frequency_unit,
                                    @frequency_value,
                                    @last_processed,
                                    @start_month,
                                    @start_day,
                                    @start_dow,
                                    @start_hour,
                                    @start_minute,
                                    @end_month,
                                    @end_day,
                                    @end_dow,
                                    @end_hour,
                                    @end_minute,
                                    dateadd(hour,h_i.iteration,(select min(x.x) from (values (@last_processed),(@utcdatetime)) as x(x)))
                                ) process_flag
                        from
                            db_sys.iteration h_i
                        where
                            (
                                h_i.iteration < 10000
                            )
                    ) iteration
            ) x
        where
            x.process_flag = 1
        order by
            x.iteration

        set @next_due = datetime2fromparts(datepart(year,@next_due),datepart(month,@next_due),datepart(day,@next_due),datepart(hour,@next_due),isnull(@start_minute,0),0,0,0)

    end

if @frequency_unit = 'day'

    begin

        select top 1
            @next_due = x.next_due
        from
            (
                select 
                    iteration.next_due,
                    iteration.process_flag,
                    iteration.iteration
                from
                    (
                        select
                            h_i.iteration,
                            dateadd(day,h_i.iteration,(select min(x.x) from (values (@last_processed),(@utcdatetime)) as x(x))) next_due,
                            db_sys.fn_set_process_flag
                                (
                                    @frequency_unit,
                                    @frequency_value,
                                    @last_processed,
                                    @start_month,
                                    @start_day,
                                    @start_dow,
                                    @start_hour,
                                    @start_minute,
                                    @end_month,
                                    @end_day,
                                    @end_dow,
                                    @end_hour,
                                    @end_minute,
                                    dateadd(day,h_i.iteration,(select min(x.x) from (values (@last_processed),(@utcdatetime)) as x(x)))
                                ) process_flag
                        from
                            db_sys.iteration h_i
                        where
                            (
                                h_i.iteration < 10000
                            )
                    ) iteration
            ) x
        where
            x.process_flag = 1
        order by
            x.iteration

        set @next_due = datetime2fromparts(datepart(year,@next_due),datepart(month,@next_due),datepart(day,@next_due),isnull(@start_hour,@ds_offset_start),isnull(@start_minute,0),0,0,0)

    end

if @frequency_unit = 'week'

    begin

        select top 1
            @next_due = x.next_due
        from
            (
                select 
                    iteration.next_due,
                    iteration.process_flag,
                    iteration.iteration
                from
                    (
                        select
                            h_i.iteration,
                            dateadd(week,h_i.iteration,(select min(x.x) from (values (@last_processed),(@utcdatetime)) as x(x))) next_due,
                            db_sys.fn_set_process_flag
                                (
                                    @frequency_unit,
                                    @frequency_value,
                                    @last_processed,
                                    @start_month,
                                    @start_day,
                                    @start_dow,
                                    @start_hour,
                                    @start_minute,
                                    @end_month,
                                    @end_day,
                                    @end_dow,
                                    @end_hour,
                                    @end_minute,
                                    dateadd(week,h_i.iteration,(select min(x.x) from (values (@last_processed),(@utcdatetime)) as x(x)))
                                ) process_flag
                        from
                            db_sys.iteration h_i
                        where
                            (
                                h_i.iteration < 10000
                            )
                    ) iteration
            ) x
        where
            x.process_flag = 1
        order by
            x.iteration

        set @next_due = dateadd(hour,isnull(@start_hour,@ds_offset_start),dateadd(minute,isnull(@start_minute,0),convert(datetime2(0),db_sys.fn_datefrom_year_week(datepart(year,@next_due),datepart(week,@next_due),isnull(@start_dow,1)))))

    end

if @frequency_unit = 'month'

    begin

        select top 1
            @next_due = x.next_due
        from
            (
                select 
                    iteration.next_due,
                    iteration.process_flag,
                    iteration.iteration
                from
                    (
                        select
                            h_i.iteration,
                            dateadd(month,h_i.iteration,(select min(x.x) from (values (@last_processed),(@utcdatetime)) as x(x))) next_due,
                            db_sys.fn_set_process_flag
                                (
                                    @frequency_unit,
                                    @frequency_value,
                                    @last_processed,
                                    @start_month,
                                    @start_day,
                                    @start_dow,
                                    @start_hour,
                                    @start_minute,
                                    @end_month,
                                    @end_day,
                                    @end_dow,
                                    @end_hour,
                                    @end_minute,
                                    dateadd(month,h_i.iteration,(select min(x.x) from (values (@last_processed),(@utcdatetime)) as x(x)))
                                ) process_flag
                        from
                            db_sys.iteration h_i
                        where
                            (
                                h_i.iteration < 1000
                            )
                    ) iteration
            ) x
        where
            x.process_flag = 1
        order by
            x.iteration

        set @next_due = datetime2fromparts(datepart(year,@next_due),datepart(month,@next_due),isnull(@start_day,1),isnull(@start_hour,@ds_offset_start),isnull(@start_minute,0),0,0,0)

    end

if @frequency_unit = 'year'

    begin

        select top 1
            @next_due = x.next_due
        from
            (
                select 
                    iteration.next_due,
                    iteration.process_flag,
                    iteration.iteration
                from
                    (
                        select
                            h_i.iteration,
                            dateadd(year,h_i.iteration,(select min(x.x) from (values (@last_processed),(@utcdatetime)) as x(x))) next_due,
                            db_sys.fn_set_process_flag
                                (
                                    @frequency_unit,
                                    @frequency_value,
                                    @last_processed,
                                    @start_month,
                                    @start_day,
                                    @start_dow,
                                    @start_hour,
                                    @start_minute,
                                    @end_month,
                                    @end_day,
                                    @end_dow,
                                    @end_hour,
                                    @end_minute,
                                    dateadd(year,h_i.iteration,(select min(x.x) from (values (@last_processed),(@utcdatetime)) as x(x)))
                                ) process_flag
                        from
                            db_sys.iteration h_i
                        where
                            (
                                h_i.iteration < 100
                            )
                    ) iteration
            ) x
        where
            x.process_flag = 1
        order by
            x.iteration

        set @next_due = datetime2fromparts
            (
                datepart(year,@next_due),
                datepart(month,@next_due),
                datepart(day,@next_due),
                datepart(hour,@next_due),
                datepart(minute,@next_due),
                0,
                0,
                0
            )

    end

if @set_overdue_now = 1 and @next_due < @utcdatetime set @next_due = @utcdatetime

return @next_due

end