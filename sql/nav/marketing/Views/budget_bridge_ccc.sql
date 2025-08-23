create   view [marketing].[budget_bridge_ccc]

as

select
    (c.[key]*10000) + (r.[key]*100) + (a.[key]*10) + s.[key] key_combo_ccc,
    c.[Name] [Cost Centre],
    r.[Return Receipt],
    a.[Affiliate Sale],
    s.[Service Item]
from 
    (
        select 0 [key], 'Under Revision' [Name]
    ) c
, 
    (
        select 0 [key], 'No' [Return Receipt] union all select 1, 'Yes'
    ) r
, 
    (
        select 0 [key], 'No' [Affiliate Sale] union all select 1, 'Yes'
    ) a
, 
    (
        select 0 [key], 'No' [Service Item] union all select 1, 'Yes'
    ) s
GO
