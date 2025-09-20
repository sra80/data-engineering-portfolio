create or alter procedure [db_sys].[sp_MSreplication_subscriptions_monitor]

as

set nocount on

merge db_sys.MSreplication_subscriptions_monitor t
using dbo.MSreplication_subscriptions s
on (t.publisher = s.publisher and t.publisher_db = s.publisher_db and t.publication = s.publication)
when not matched by target then
    insert (publisher, publisher_db, publication, transaction_timestamp, transaction_timestamp_arrival, issue_notification, notification_count, issue_count)
    values (s.publisher, s.publisher_db, s.publication, s.transaction_timestamp, getutcdate(), 0, 0, 0)
when matched and s.transaction_timestamp > t.transaction_timestamp then
    update set
        t.transaction_timestamp = s.transaction_timestamp,
        t.transaction_timestamp_arrival = getutcdate(),
        t.notification_count = 0,
        t.issue_notification = 0,
        t.is_outofsync = 0;

merge db_sys.MSreplication_subscriptions_monitor t
using dbo.MSreplication_subscriptions s
on (t.publisher = s.publisher and t.publisher_db = s.publisher_db and t.publication = s.publication and t.transaction_timestamp = s.transaction_timestamp)
when matched
    and t.publisher_db = 'NAV_PROD'
    and t.publisher = 'navprod-db1'
    and datediff(minute,t.transaction_timestamp_arrival,getutcdate()) >= 5
    and
        (
            t.last_notification is null
         or datediff(minute,t.last_notification,getutcdate()) >= 30
         )
    and t.notification_count < 10 then
    update set
        t.issue_notification = 1,
        t.issue_count = case when t.notification_count = 0 then t.issue_count + 1 else t.issue_count end,
        t.resolved_notification = 1,
        t.is_outofsync = 1;
GO