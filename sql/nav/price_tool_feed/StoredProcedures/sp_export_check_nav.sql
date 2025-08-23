create or alter procedure price_tool_feed.sp_export_check_nav

as

declare @t table (nav_db nvarchar(max), oldest datetime2(0), delayed int, error int)

declare @message nvarchar(max), @subject nvarchar(255), @nav_db nvarchar(max), @oldest datetime2(0), @delayed int, @error int, @place_holder uniqueidentifier

insert into @t (nav_db, oldest, delayed, error)
select
    c.NAV_DB,
    min(case when h.[Status] = 0 then h.[Created Date_Time] end) oldest,
    sum(case when h.[Status] = 0 then 1 else 0 end) delayed,
    sum(case when h.[Status] = 1 then 1 else 0 end) error
from
    hs_consolidated.[Sales Price Holding Table] h
join
    db_sys.Company c
on
    (
        h.company_id = c.ID
    )
where
    (
        h.[Ignored] = 0
    and
        (
            h.[Status] = 1
        or
            (
                h.[Status] = 0
            and datediff(minute,h.[Created Date_Time],getutcdate()) > 30
            )
        )
    )
group by
    c.NAV_DB

declare [d531d349-41f0-41fc-8848-e5c7c9ac7c6e] cursor for select nav_db, oldest, delayed, error from @t

open [d531d349-41f0-41fc-8848-e5c7c9ac7c6e]

fetch next from [d531d349-41f0-41fc-8848-e5c7c9ac7c6e] into @nav_db, @oldest, @delayed, @error

while @@fetch_status = 0

begin /*8e0f*/

    set @place_holder = null

    set @subject = concat('Issues Importing Sales Prices from the Holding Table in ',@nav_db)

    select top 1 
        @place_holder = tnl.place_holder
    from 
        db_sys.team_notification_log tnl
    outer apply
        (
            select top 1
                x.place_holder
            from
                db_sys.team_notification_log x
            where
                (
                    tnl.place_holder = try_convert(uniqueidentifier,x.message_subject)
                )
        ) closed
    where 
        (
            tnl.message_subject = @subject
        and convert(date,tnl.addTS) = convert(date,getutcdate())
        and closed.place_holder is null
        )
    order by ID

    if @place_holder is null set @message = '' else set @message = 'Just an update, '

    if @delayed > 0

    begin /*b4ab*/

        if @place_holder is null

            begin /*51a3*/

                set @message += 'There '

                if @delayed = 1 set @message += 'is ' else set @message += 'are '

                set @message += format(@delayed,'###,###,##0')

                if @delayed = 1 set @message += ' entry ' else set @message += ' entries '

                set @message += concat('in the sales price holding table in ',@nav_db,' that ')

                if @delayed = 1 set @message += 'has ' else set @message += 'have '

                set @message += 'not been processed yet. '

                if @delayed = 1 set @message += 'This entry arrived in the holding table ' else set @message += 'The earliest of these entries arrived in the holding table '

                set @message += concat(db_sys.fn_datediff_string(@oldest,getutcdate(),5),' ago.')

            end /*51a3*/

        else

            begin /*857c*/

                if @delayed = 1 set @message += 'there is 1 delay'
                if @delayed > 1 set @message += concat('there are ',format(@delayed,'###,###,##0'),' delays')
            
            end /*857c*/

    end /*b4ab*/

    if @error > 0

    begin /*9baf*/

        if @delayed > 0 set @message += char(10)

        if @place_holder is null

            begin /*47a9*/

                set @message += 'There '

                if @error = 1 set @message += 'is ' else set @message += 'are '

                if @delayed > 0 set @message += 'also '

                set @message += format(@error,'###,###,##0')

                if @error = 1 set @message += ' entry ' else set @message += ' entries '

                set @message += concat('in the sales price holding table in ',@nav_db,' that ')

                if @error = 1 set @message += 'has ' else set @message += 'have '

                set @message += 'errored.'

            end /*47a9*/

        else

            begin /*f698*/

                if @delayed > 0 set @message += ' and ' else if @error = 1 set @message += 'there is ' else set @message += 'there are '
                if @error = 1 set @message += '1 error'
                if @error > 1 set @message += concat(format(@error,'###,###,##0'),' errors')

            end /*f698*/

    end /*9baf*/

    if @delayed > 0 or @error > 0

      begin /*4afc*/

        if @place_holder is not null set @message += ' in the price holding table.'

        exec db_sys.sp_email_notifications
          @subject = @subject,
          @bodyIntro = @message,
          @is_team_alert = 1,
          @tnc_id = 1,
          @place_holder = @place_holder

        end /*4afc*/

    else

        begin /*249c*/

        set @subject = lower(@place_holder)

        if (select isnull(sum(1),0) from db_sys.team_notification_log where message_subject = @subject) = 0

            begin /*ad29*/

                exec db_sys.sp_email_notifications
                @subject = @subject,
                @bodyIntro = 'Just an update, all previous issues in the price holding table have now been resolved.',
                @is_team_alert = 1,
                @tnc_id = 1,
                @place_holder = @place_holder

            end /*ad29*/

        end /*249c*/

    fetch next from [d531d349-41f0-41fc-8848-e5c7c9ac7c6e] into @nav_db, @oldest, @delayed, @error

end /*8e0f*/

close [d531d349-41f0-41fc-8848-e5c7c9ac7c6e]
deallocate [d531d349-41f0-41fc-8848-e5c7c9ac7c6e]