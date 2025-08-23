create or alter procedure [ext].[sp_Channel] 
 
as 
 
declare @count int 
 
select @count = count(*) from ext.Channel where convert(date,addedTSUTC) = convert(date,getutcdate()) and Group_Code = 7 
 
if @count > 0 
 
begin 
 
declare @sub nvarchar(30) 
declare @msg1 nvarchar(max) 
declare @msg2 nvarchar(max) 
 
set @msg1 = 'This message requires a response from a member of the Business Intelligence Team.<p>' 
 
	if @count = 1  
 
	begin 
 
	set @sub = 'NAV: New Order Channel' 
	set @msg1 += 'The following sale order channel is new and has been recently added:<p> <ul style="padding-left:20px"> ' 
	set @msg2 = 'The channel code has been assigned to the group <b>New*</b>, please re-assign to the appropriate channel group.' 
 
	end 
 
	if @count > 1  
	 
	begin 
	 
	set @sub = 'NAV: New Order Channels' 
	set @msg1 += 'The following sale order channels are new and have recently been added:<p> <ul style="padding-left:20px"> ' 
	set @msg2 = 'The channel codes have been assigned to the group <b>New*</b>, please re-assign to their appropriate channel groups.' 
 
	end 
 
select @msg1 = @msg1 + '<li>' + Channel_Code + ' (' + (select NAV_DB from db_sys.Company c where Channel.company_id = c.ID) + ')</li>' from ext.Channel where convert(date,addedTSUTC) = convert(date,getutcdate()) and Group_Code = 7 order by company_id, ID 
 
set @msg1 = @msg1 + '</ul> <p>' 
 
set @msg1 += @msg2 
 
	exec db_sys.sp_email_notifications
		@subject = @sub ,
		@bodyIntro = @msg1,
		@is_team_alert = 1,
    	@tnc_id = 6
		 
end
GO
