CREATE view marketing.Users

as

select
    u.ID key_user,
    concat(u.firstname,' ',u.surname) Fullname,
    g.group_name Team
from
    db_sys.Users u
left join
    mitel.agent_group g
on
    (
        u.mitel_user_key = g.id
    )
GO
