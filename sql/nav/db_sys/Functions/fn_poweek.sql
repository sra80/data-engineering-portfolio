create or alter function db_sys.fn_poweek
    (
        @datetime datetime2(0) = null
    )

returns decimal(4,3) --portion of week

as

begin

return 
    db_sys.fn_divide
        (
            datediff
                (
                    second,
                    db_sys.foweek(isnull(@datetime,getutcdate()),0),
                    isnull(@datetime,getutcdate())
                ),
            datediff
                (
                    second,
                    convert
                        (
                            datetime2(0),
                            db_sys.foweek
                                (
                                    isnull(@datetime,getutcdate()),
                                    0
                                )
                        ),
                    dateadd
                        (
                            second,
                            86399,
                            convert
                                (
                                    datetime2(0),
                                    db_sys.fn_eoweek
                                        (
                                            isnull(@datetime,getutcdate())
                                        )
                                )
                        )
                ),
            0
        )

end

