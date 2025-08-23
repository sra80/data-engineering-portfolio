--ext.sp_Location (procedure) *done*

create or alter procedure [ext].[sp_Location]

 as

 --adopted from [dbo].[B15_newLocations] 

 declare @count int

 select @count = count(*) from ext.[Location] where convert(date,addedUTC) >= dateadd(day,-1,convert(date,getutcdate()))

 if @count > 0

 begin

 declare @sub nvarchar(30)
 declare @msg1 nvarchar(max)
 declare @msg2 nvarchar(max)

 set @msg1 = 'This message requires a response from a member of the Procurement Team.<p>'

 	if @count = 1

 	begin

 	set @sub = 'NAV: New Warehouse Location'
 	set @msg1 += 'The following location is new and has been recently added to NAV:<p> <ul style="padding-left:20px"> '
 	set @msg2 = 'If this location will be holding finished goods or used for the dispatch of finished goods, please let us know, we require this information for reporting purposes.<p>'

 	end

 	if @count > 1
 	
 	begin
 	
 	set @sub = 'NAV: New Warehouse Locations'
 	set @msg1 += 'The following locations are new and have recently been added to NAV:<p> <ul style="padding-left:20px"> '
 	set @msg2 = 'If any of these locations will be holding finished goods or used for the dispatch of finished goods, please let us know, we require this information for reporting purposes.<p>'

 	end

 select @msg1 = @msg1 + '<li>' + location_code + ' (' + (select NAV_DB from db_sys.Company c where l.company_id = c.ID) + ')</li>' from ext.[Location] l where convert(date,addedUTC) = convert(date,getutcdate()) order by l.ID

 set @msg1 = @msg1 + '</ul> <p>'

 set @msg1 += @msg2

 	exec db_sys.sp_email_notifications
 		 @to = 'user@example.com'
 		,@cc = 'user@example.com'
 		,@subject = @sub
 		,@bodyIntro = @msg1
 		
 end
GO
