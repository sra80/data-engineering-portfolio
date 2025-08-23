create view marketing.CSH_Opt_Source_Dimension

as

select
    id,
    opt_source_clean [Source]
from
    marketing.csh_opt_source

union

select
    -1,
    'unknown'
GO
