create view _audit.[UK$G_L Register]

as

select
    *
from
    [dbo].[UK$G_L Register] d
cross apply
    (select min([Entry No_]) first_en, max([Entry No_]) last_en from _audit.[UK$G_L Entry]) a
where
    d.[From Entry No_] >= a.first_en
and d.[From Entry No_] <= a.last_en
GO
