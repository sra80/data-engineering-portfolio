create function [db_sys].[fn_auditLog_avgGapBetweenRunsSeconds]
    (
        @eventName nvarchar(64)
    )

returns int

as

begin

declare @auditLog_avgGapBetweenRunsSeconds int

select top 1
        @auditLog_avgGapBetweenRunsSeconds = percentile_cont(0.5) within group (order by datediff(second,d.eventUTCStart,a.eventUTCStart)) over ()
    from
        db_sys.auditLog a
    cross apply
        (
            select
                max(ID) ID_previous
            from
                db_sys.auditLog b
            where
                (
                    a.eventType = b.eventType
                and a.eventName = b.eventName
                and a.eventDetail = b.eventDetail
                and a.ID > b.ID
                )
        ) c
    join
        db_sys.auditLog d
    on
        (
            c.ID_previous = d.ID
        )
    where
        (
            a.eventType = 'Procedure'
        and a.eventDetail = 'Procedure Outcome: Success'
        and a.ID in (select ID from (select ID, row_number() over (partition by eventType, eventName order by ID desc) r from db_sys.auditLog) x where x.r <= 50)
        and a.eventName = @eventName
        )

return @auditLog_avgGapBetweenRunsSeconds

end
GO
