CREATE view [ext].[vw_Platform_Undefined]

as

select
    company_id,
    Integration_Code, 
    Channel_Code, 
    Order_Prefix
from
    ext.Platform_Undefined
where
    (
        place_holder = (select place_holder from db_sys.email_notifications_schedule where ID = 29)
    )
GO
