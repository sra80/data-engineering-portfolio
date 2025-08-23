CREATE   procedure [ext].[sp_brandMaker_sync]

as

merge ext.Item t
using ext.vw_brandMaker_sync s
on (t.company_id = 1 and t.No_ = s.item_sku)
when matched and s.bm_checksum != isnull(t.bm_checksum,0) and t.outstandingBMSync = 0 then update set
	 outstandingBMSync = 1
	,lastBMSyncRequest = getutcdate()
	,countBMSyncRequest = countBMSyncRequest + 1
	,bm_checksum = s.bm_checksum
when not matched by target then
	insert (company_id, No_, outstandingBMSync, firstBMSyncRequest, lastBMSyncRequest, countBMSyncRequest, bm_checksum)
	values (1, s.item_sku, 1, getutcdate(), getutcdate(), 1, s.bm_checksum);
GO
