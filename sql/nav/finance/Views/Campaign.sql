
create   view finance.Campaign

as

select
    e.ID keyCampaign, 
    [No_] [Campaign Code],
    [Description] [Campaign Description]
from
	[hs_consolidated].[Campaign] h
join
    ext.Campaign e
on
    (
        h.company_id = e.company_id
    and h.No_ = e.campaign_code
    )
GO
