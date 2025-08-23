CREATE function ext.fn_Customer_opt_in_status
    (
        @cus nvarchar(20),
        @date_start date = null,
        @date_end date = null,
        @opt_type nvarchar(20) = 'EMAIL'
    )

returns table

as


return
    (
        with 
        opt_status_base as
            (
                select
                    change_date,
                    opt_in_status,
                    opt_source
                from
                    (
                    select
                        case [Status] when 0 then 1 else 0 end opt_in_status,
                        convert(date,[Modified DateTime]) change_date,
                        case when lag([Status]) over (order by [Modified DateTime]) = [Status] then 0 else 1 end state_change,
                        [Modified DateTime],
                        opt_source
                    from
                        (
                        select 
                            [Status], 
                            [Modified DateTime],
                            case when [Entry No_] = max([Entry No_]) over (partition by convert(date,[Modified DateTime])) then 1 else 0 end last_change,
                            opt_source 
                        from
                            ( 
                                select
                                    [Status],
                                    [Modified DateTime],
                                    [Entry No_],
                                    nullif(marketing.fn_csh_opt_source([Web Page URL]),'') opt_source
                                from
                                    [UK$Customer Preferences Log]
                                where
                                (
                                    [Customer No_] = @cus
                                    and convert(date,[Modified DateTime]) >= isnull(@date_start,(select top 1 [Created Date] from [dbo].[UK$Customer] where No_ = @cus))
                                    and convert(date,[Modified DateTime]) <= isnull(@date_end,convert(date,getutcdate()))
                                    and [Record Code] = @opt_type
                                )

                                union all

                                select 
                                    isnull((select top 1 [Status] from [UK$Customer Preferences Log] where [Customer No_] = @cus and convert(date,[Modified DateTime]) <= isnull(@date_start,(select top 1 [Created Date] from [dbo].[UK$Customer] where No_ = @cus)) and [Record Code] = @opt_type),1) [Status],
                                    isnull(@date_start,(select top 1 [Created Date] from [dbo].[UK$Customer] where No_ = @cus)) [Modified DateTime],
                                    0,
                                    null
                            ) cpl
                        ) cpl
                        where
                            cpl.last_change = 1
                        ) n
                    where
                        (
                            n.state_change = 1
                        )
                )

        , opt_status as
                    (
                        select
                            opt_status_base.change_date,
                            opt_status_base.opt_in_status,
                            opt_source
                        from
                            opt_status_base
                        where
                            opt_status_base.change_date >= isnull(@date_start,(select top 1 [Created Date] from [dbo].[UK$Customer] where No_ = @cus))   
                    )

            select
                opt_status.change_date _start_date,
                isnull(_end_date._end_date,@date_end) _end_date,
                isnull(opt_status.opt_in_status,0) opt_in_status,
                opt_source
            from 
                opt_status
            outer apply
                (
                    select top 1 
                        dateadd(day,-1,change_date) _end_date 
                    from 
                        opt_status x 
                    where
                        ( 
                            opt_status.change_date < x.change_date
                        ) 
                    order by 
                        change_date asc
                ) _end_date
    )
GO
