create procedure ext.sp_Customer_Amazon

as

insert into ext.Customer_Amazon (hs_cus, am_add_code)
select 
    c.No_,
    a.Code
from
    [UK$Ship-to Address] a
join
    [UK$Customer] c
on
    (
        a.[Post Code] = c.[Post Code]
    and case when charindex(' ',a.[Name]) > 0 then substring(a.Name,len(a.Name)-charindex(' ',reverse(a.[Name]))+2,convert(int,charindex(' ',reverse(a.[Name])))-1) else a.Name end = case when charindex(' ',c.[Name]) > 0 then substring(c.Name,len(c.Name)-charindex(' ',reverse(c.[Name]))+2,convert(int,charindex(' ',reverse(c.[Name])))-1) else c.Name end
    and left(isnull(nullif(a.[Name 2],''),a.[Address]),2) = left(isnull(nullif(c.[Name 2],''),c.[Address]),2)
    and right(isnull(nullif(a.[Name 2],''),a.[Address]),2) = right(isnull(nullif(c.[Name 2],''),c.[Address]),2)
    )
where
    a.[Customer No_] = 'C0435139'
and len(a.[Post Code]) > 0
and not exists (select 1 from ext.Customer_Amazon x where c.No_ = x.hs_cus and a.Code = x.am_add_code)
GO
