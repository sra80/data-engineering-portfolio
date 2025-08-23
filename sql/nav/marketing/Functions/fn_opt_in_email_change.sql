CREATE function marketing.fn_opt_in_email_change
    (
        @cus nvarchar(20),
        @_start_date date,
        @opt_in_email bit,
        @opt_state_change bit
    )

returns bit

as

begin

    if (
            exists 
                (
                select
                    _start_date
                from
                    (
                        select
                            min(_start_date) _start_date
                        from
                            (
                            select
                                [Start Date] _start_date
                            from
                                marketing.CSH_Moving_Extended
                            where
                                No_ = @cus

                            union all

                              select
                                _start_date
                            from
                                ext.Prospect_OptIn_History
                            where
                                cus = @cus    
                            ) n
                    ) x
                where
                    (
                        x._start_date = @_start_date
                    )
                )
        and @opt_in_email = 0
    ) 
        set @opt_state_change = 0 

return @opt_state_change

end
GO
