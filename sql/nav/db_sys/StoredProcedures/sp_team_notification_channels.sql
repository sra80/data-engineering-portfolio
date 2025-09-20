create or alter procedure db_sys.sp_team_notification_channels
    (
        @json nvarchar(max)
    )

as

set nocount on

;with j ([level], [base_key], [key], [value], [type]) as
    (
        select 
            0 [level],
            x1.[key],
            x1.[key],
            x1.[value],
            x1.[type]
        from 
            openjson(@json) x1

        union all

        select
            j.[level] + 1,
            j.[key],
            x2.[key],
            x2.[value],
            x2.[type]
        from
            j
        cross apply
            openjson(j.[value]) x2
        where
            (
                j.[type] in (4,5)
            )
    )

merge db_sys.team_notification_channels t
using 
    (
        select
            id.[value] channel_id,
            displayName.[value] channel_name,
            webUrl.[value] webUrl
        from
            (
                select
                    j.[base_key],
                    j.[value]
                from
                    j
                where
                    (
                        j.[level] = 2
                    and j.[key] = 'id'
                    )
            ) id
        outer apply
            (
                select
                    j.[base_key],
                    j.[value]
                from
                    j
                where
                    (
                        j.[level] = 2
                    and j.[key] = 'displayName'
                    and j.[base_key] = id.[base_key]
                    )
            ) displayName
        outer apply
            (
                select
                    j.[base_key],
                    j.[value]
                from
                    j
                where
                    (
                        j.[level] = 2
                    and j.[key] = 'webUrl'
                    and j.[base_key] = id.[base_key]
                    )
            ) webUrl
    ) s
on (t.channel_id = s.channel_id)
when not matched by target then
insert (channel_id, channel_name, webUrl)
values (s.channel_id, s.channel_name, s.webUrl)
when matched and (s.channel_name != t.channel_name or s.webUrl != t.webUrl or t.webUrl is null) then
update set
    t.channel_name = s.channel_name,
    t.webUrl = s.webUrl,
    t.updateTS = sysdatetime()
when not matched by source and t.deleteTS is null then
update set
    t.deleteTS = sysdatetime();
GO

GRANT EXECUTE
    ON OBJECT::[db_sys].[sp_team_notification_channels] TO [hs-bi-datawarehouse-la-aad-teams]
    AS [dbo];
GO
