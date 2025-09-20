create or alter procedure [db_sys].[sp_email_notifications]

	 (
	 @to nvarchar(max) = null
	,@cc nvarchar(max) = null
	,@subject nvarchar(255) = null
	,@bodyIntro nvarchar(max) = null
	,@bodySource nvarchar(255) = null
	,@bodyOutro nvarchar(max) = null
	,@extSign bit = 0
	,@importance nvarchar(8) = 'Normal' --Low,Normal,High
	,@greeting bit = 1
	,@valign tinyint = 2
	,@notifications_schedule_ID int = -1
    ,@auditLog_ID int = null
    ,@is_team_alert bit = 0 -- --
    ,@tnc_id int = null
	,@place_holder uniqueidentifier = null
	)
as

begin

set nocount on

if @place_holder is null

	begin

	select @place_holder = reply_place_holder from db_sys.email_notifications_schedule where ID = @notifications_schedule_ID

	end

if @auditLog_ID is null and @place_holder is not null select @auditLog_ID = ID from db_sys.auditLog where place_holder = @place_holder

if @auditLog_ID is null set @auditLog_ID = -1

declare @tnl_ID int, @teams_message_id bigint, @bodySource_hashbytes varbinary(32), @reply_place_holder uniqueidentifier, @is_reply_on_same bit, @enl_ID int

select top 1 @teams_message_id = teams_message_id from db_sys.team_notification_log where place_holder = @place_holder

if @place_holder is null or @teams_message_id is not null set @place_holder = newid()

select @bodySource = replace(replace(@bodySource,'[',''),']','')

declare @split int, @schema nvarchar(32), @object nvarchar(128), @to_internal nvarchar(max), @to_external nvarchar(max), @cc_internal nvarchar(max), @cc_external nvarchar(max)

set @split = charindex('.',@bodySource)

if @split > 0 set @schema = left(@bodySource,@split-1) else set @schema = 'dbo'

if @split > 0 set @object = SUBSTRING(@bodySource,@split+1,LEN(@bodySource)-@split) else set @object = @bodySource

declare @bodySourceCHK bit = 0, @object_id int

select @bodySourceCHK = 1, @object_id = object_id
from sys.objects
where object_name(object_id) = @object and schema_name(schema_id) = @schema

--MOD #03 b)
if @bodySource is not null and @bodySourceCHK = 1

	begin

	--check there are records
	declare @countRecsSQL nvarchar(max)
	declare @countRecs int

	set @countRecsSQL = 'select @countRecs = count(*) from ' + @bodySource

	exec sp_executesql @countRecsSQL, N'@countRecs nvarchar(max) out',@countRecs out

		if @countRecs > 0 --checks if table/view has data BEGIN

		begin

		declare @dur int = 0

		declare @body nvarchar(max), @body2 nvarchar(max), @body_team nvarchar(max)

		--Table data
		--declare @view nvarchar(40)

		declare @tableHeaders nvarchar(max) = ''
		declare @tableCol# int
		declare @tableSQL nvarchar(max) = ''
		declare @tableContent nvarchar(max) = ''

		--set @view = @bodySource

		select
			@tableHeaders = @tableHeaders + char(10) + char(9) + '<th bgcolor=#4472C4><font color=#FFFFFF>' + name + '</font></th>' --
		from 
			sys.columns 
		where 
			--object_name(object_id) = @object
			object_id = @object_id
		and name not in ('bg','fg','r') --MOD #13
		and name not like N'x_%' --MOD #23
		order by column_id

		select
			@tableCol# = max(column_id)
		from 
			sys.columns 
		where 
			--object_name(object_id) = @view
			object_id = @object_id
		and name not in ('bg','fg','r') --MOD #13
		and name not like N'x_%' --MOD #23

		--MOD #02 
		declare @bg bit = 0

		select
			@bg = 1
		from 
			sys.columns 
		where 
			--object_name(object_id) = @view
			object_id = @object_id
			and name = 'bg'

		
		--MOD #22
		declare @fg bit = 0

		select
			@fg = 1
		from 
			sys.columns 
		where 
			--object_name(object_id) = @view
			object_id = @object_id
			and name = 'fg'
		
		--MOD #13
		declare @r bit = 0

		select
			@r = 1
		from
			sys.columns
		where 
			--object_name(object_id) = @view
			object_id = @object_id
			and name = 'r'

		set @tableSQL = @tableSQL + 'set @tableContent = cast' + char (10) + char(9) + '(' + char(10) + replicate(char(9),2) + '(' + char(10) + replicate(char(9),2)

		set @tableSQL = @tableSQL + 'select ' + char(10) + char(9) + char(9) + char(9)

		if @bg = 1 set @tableSQL = @tableSQL + 'bg "@bgcolor",'''','

		declare @i int = 1

		declare @colName nvarchar(100)

		declare @col1 nvarchar(100) --MOD #07

		while @i <= @tableCol#

		begin

		select 
			 @colName = c.name 
		from 
			sys.columns c
		where 
			(
				--object_name(object_id) = @vie
				object_id = @object_id
			and column_id = @i
			)

		if @bg = 0 and @i = 1 and @r = 0 set @tableSQL = @tableSQL + 'case when convert(nvarchar,['+@colName+']) = ''Total'' then ''#4472C4'' else case when (row_number() over (order by [' + @colName + '])%2)=0 then ''#D9E1F2'' else ''#FFFFFF'' end end "@bgcolor",'''',' --MOD #05 #09

		if @bg = 0 and @i = 1 and @r = 1 set @tableSQL = @tableSQL + 'case when convert(nvarchar,['+@colName+']) = ''Total'' then ''#4472C4'' else case when (row_number() over (order by r)%2)=0 then ''#D9E1F2'' else ''#FFFFFF'' end end "@bgcolor",'''',' --MOD #05 #09 #13
		
		if /*@bg = 0 and MOD #15*/ @i = 1 set @col1 = @colName --MOD #07

		if @fg = 1 set @tableSQL = @tableSQL + '''color:''+fg+'';''+' else set @tableSQL = @tableSQL + '''color:#000000;''+' 

		set @tableSQL = @tableSQL + 'case when isnumeric(convert(nvarchar,['+@colName+']))=1 then ''text-align:right'' when len([' + @colName + '])-len(replace(['+@colName+'],''/'',''''))=2 or isdate(convert(nvarchar,['+@colName+']))=1 then ''text-align:center'' else ''text-align:left'' end "td/@style",' --MOD #06 #09 #16

		if @bg = 0 set @tableSQL = @tableSQL + 'case when convert(nvarchar,[' + @col1 + ']) = ''Total'' then ''total'' else ''black'' end "td/@class",' --MOD #07

		set @tableSQL = @tableSQL + 'case when isdate(convert(nvarchar,[' + @colName + ']))=1 then convert(nvarchar,[' + @colName + '],103) else convert(nvarchar(255),[' + @colName + ']) end "td"'

		if @i < @tableCol# set @tableSQL = @tableSQL + ','''','

		set @i +=1

		end

		set @tableSQL = @tableSQL + char(10) + char(9) + char(9) + 'from' + char(10) + replicate(char(9),3) + @bodySource + char(10) + replicate(char(9),2)  
		
		if @r = 0 set @tableSQL = @tableSQL + 'order by case when convert(nvarchar,[' + @col1 + ']) = ''Total'' then ''zzzzzzzz'' else [' + @col1 + '] end' + char(10) + replicate(char(9),2) --MOD #13

		if @r = 1 set @tableSQL = @tableSQL + 'order by r' + char(10) + replicate(char(9),2) --MOD #13

		set @tableSQL = @tableSQL + 'for xml path(''tr''),elements' + char(10) + char(9) + char(9) + ')' + char(10) + char(9) + 'as nvarchar(max))'
		exec sp_executesql @tableSQL, N'@tableContent nvarchar(max) out',@tableContent out

		set @tableContent = replace(@tableContent,'&lt;','<') --MOD #09
		set @tableContent = replace(@tableContent,'&gt;','>') --MOD #09

		--Table data end

		declare @bodyTable nvarchar(max) = ''

		set @bodyTable = @bodyTable + '<table><tr>'

		set @bodyTable = @bodyTable + @tableHeaders + '</tr>'

		set @bodyTable = @bodyTable + @tableContent +'</table>'

		end --checks if table/view has data END

		end --MOD #03 a) END

			set @body =	'<!DOCTYPE html><html ><head>
							<title>' + coalesce(@bodySource,@subject,'SQL Generated') + '</title>
							<style>
							table, th, td {
       	   								  border: 1px solid #8EA9DB;
										  }
							table 		  {
    									  border-collapse: collapse;
    									  width: auto;
										  margin: 0 auto;
										  align="center";
										  }
							th, td 		  {
    									  padding: 5px;
										  }
							th 			  {
    									  background-color: #4472C4;
    									  color: white;
										  text-align: center
										  vertical-align: middle
										  }
							td			  {
										  text-align: left
										  }
							tr:hover	  {background-color: #D3D3D3;}
							td.total	  {color: #FFFFFF;font-weight: bold}
							td.black	  {color: #000000;vertical-align: ' + case @valign when 1 then 'top' when 2 then 'middle' when 3 then 'bottom' else 'baseline' end + '}

							'

				set @body =	@body + '
							</style>
						</head>
					<body>
					'

	--greeting
	--declare @timeOfDay nvarchar(10)
	--if datepart(hour,getdate()) >= 0 set @timeOfDay = 'morning'
	--if datepart(hour,getdate()) >= 12 set @timeOfDay = 'afternoon'
	--if datepart(hour,getdate()) >= 18 set @timeOfDay = 'evening'

	set @body_team = @body
	
	if @greeting = 1 set @body = @body + 'Good ***timeofday***,<p><p>'

	if @bodySource is not null and @bodySourceCHK = 1 set @body = @body + replace(isnull(@bodyIntro,'Please see as follows:'),char(10),'<p>')

	if @bodySource is not null and @bodySourceCHK = 1 set @body_team = @body_team + replace(isnull(@bodyIntro,'Please see as follows:'),char(10),'<p>')

	if @bodySource is not null and @bodySourceCHK = 1 set @body = @body + @bodyTable

	if @bodySource is not null and @bodySourceCHK = 1 set @body_team = @body_team + @bodyTable

    if @bodySource is null set @body = @body + isnull(@bodyIntro,'') --added by SE @ 27/09/2021 14:18:10+3

	if @bodySource is null set @body_team = @body_team + isnull(@bodyIntro,'') --added by SE @ 27/09/2021 14:18:10+3

	set @body = @body + '<p>' + replace(isnull(@bodyOutro,''),char(10),'<p>')

	set @body_team = @body_team + '<p>' + replace(isnull(@bodyOutro,''),char(10),'<p>')

	if right(@body,3) != '<p>' set @body = @body + '<p>' --MOD #13

	-- if right(@body_team,3) != '<p>' set @body_team = @body_team + '<p>' --MOD #13

	--if @ifYou = 1 
	
	if @greeting = 1 set @body = @body + 'If you have any questions, please don''t hesitate to contact us. <p>'

	set @body2 = @body

	if @greeting = 1

		begin

			set @body = @body + 'Kind regards, <p><b>The Business Intelligence Team</b>'

			set @body2 = @body2 + 'Kind regards, <p><b>The CompanyX Business Intelligence Team</b>'

		end

		-- begin***

	declare @channel_count int, @channel_list nvarchar(max)

	select
		@channel_count = sum(1),
		@channel_list = string_agg(concat('<li><a href="',tnc.webUrl,'">',tnc.channel_name,'</a></li>'),char(10))
	from
		db_sys.team_notification_setup tns
	join
		db_sys.team_notification_channels tnc
	on
		(
			tns.tnc_ID = tnc.ID
		)
	where
		(
			tns.ens_ID = @notifications_schedule_ID
		)

	if @channel_count = 1 set @body += '<hr>This Business Intelligence Alert can also be found in the following channel in Teams:'

	if @channel_count > 1 set @body += '<hr>This Business Intelligence Alert can also be found in the following channels in Teams:'

	if @channel_count > 0 set @body += concat('<p><ul>',@channel_list,'</ul>')

	-- end***

	-- set @body = @body --+ @signature

    if (@is_team_alert = 1 or exists (select 1 from db_sys.team_notification_channels where ID = @tnc_id and deleteTS is null)) and ((@bodySourceCHK = 1 and @countRecs > 0) or (@bodySource is null and len(@bodyIntro) > 0))

        begin

		select
			@is_reply_on_same = is_reply_on_same,
			@bodySource_hashbytes = bodySource_hashbytes,
			@reply_place_holder = reply_place_holder
		from 
			db_sys.team_notification_setup 
		where
			(
				ens_ID = @notifications_schedule_ID
			and is_reply_on_same = 1
			) 

        insert into db_sys.team_notification_log (auditLog_ID, ens_ID, message_subject, place_holder, teams_message_id, teams_root_mid)
        values (@auditLog_ID, @notifications_schedule_ID, @subject, @place_holder, @teams_message_id, @teams_message_id)

        select @tnl_ID = ID from db_sys.team_notification_log tnl where place_holder = @place_holder

        set @body_team = concat(@body_team,'<p style="font-size:8px; ">',@tnl_ID,'</p>')

        end

	set @body2 = @body2 + '</body></html>'

	set @body_team = @body_team + '</body></html>'

	--send email message

		if (@bodySourceCHK = 1 and @countRecs > 0) or (@bodySource is null and len(@bodyIntro) > 0)

			begin

                if len(@to) > 0 or len(@cc) > 0

				select
					@to_internal = email_internal,
					@to_external = email_external
				from
					db_sys.fn_email_split_internal_external(@to)

				select
					@cc_internal = email_internal,
					@cc_external = email_external
				from
					db_sys.fn_email_split_internal_external(@cc)

				if len(concat(@to_internal,@cc_internal)) > 0

					begin

						insert into db_sys.email_notifications (email_to,email_cc,email_subject,email_body,email_importance,email_notifications_schedule_ID,auditLog_ID,place_holder)
						values
							(
								@to_internal,
								@cc_internal,
								@subject,
								@body,
								@importance,
								@notifications_schedule_ID,
								@auditLog_ID,
								@place_holder
							)

						select
							@enl_ID = max(ID)
						from
							db_sys.email_notifications
						where
							(
								place_holder = @place_holder
							)

						if @enl_ID > 0

							begin

								set @body = concat(@body,'<p style="font-size:8px; ">',@enl_ID,'</p></body></html>')

							end

						else

							begin

								set @body = concat(@body,'</body></html>')

							end

						update db_sys.email_notifications set email_body = @body where ID = @enl_ID

					end

				if len(concat(@to_external,@cc_external)) > 0

					begin

						insert into db_sys.email_notifications (email_to,email_cc,email_subject,email_body,email_importance,email_notifications_schedule_ID,auditLog_ID)
						values
							(
								@to_external,
								@cc_external,
								@subject,
								@body2,
								@importance,
								@notifications_schedule_ID,
								@auditLog_ID
							)

					end

                if (@is_team_alert = 1 or exists (select 1 from db_sys.team_notification_channels where ID = @tnc_id and deleteTS is null)) and @tnl_ID >= 0

                    begin

						if @teams_message_id is null and @is_reply_on_same = 1 and @reply_place_holder is not null and @bodySource_hashbytes is not null and @bodySource_hashbytes = hashbytes('SHA2_256',@tableContent)

							begin

								update
									db_sys.team_notification_log
								set
									message_body = @body_team,
									message_reply = concat(db_sys.fn_num_ordinal((select isnull(sum(1),0) from db_sys.team_notification_log where teams_root_mid = (select teams_message_id from db_sys.team_notification_log where place_holder = @reply_place_holder))+1),' followup, the above remains unresolved.<p style="font-size:8px; ">',@tnl_ID,'</p>'),
									teams_message_id = (select top 1 teams_message_id from db_sys.team_notification_log where place_holder = @reply_place_holder),
									teams_root_mid = (select top 1 teams_message_id from db_sys.team_notification_log where place_holder = @reply_place_holder)
								where
									ID = @tnl_ID

							end

						else

							begin

								update
									db_sys.team_notification_log
								set
									message_body = @body_team
								where
									ID = @tnl_ID

								
								update
									db_sys.team_notification_setup
								set
									bodySource_hashbytes = hashbytes('SHA2_256',@tableContent),
									reply_place_holder = @place_holder
								where 
									(
										ens_ID = @notifications_schedule_ID
									and is_reply_on_same = 1
									)

							end

                        
                        if exists (select 1 from db_sys.team_notification_channels where ID = @tnc_id and deleteTS is null) and (select isnull(sum(1),0) from db_sys.team_notification_auditLog where tnl_ID = @tnl_ID and tnc_ID = @tnc_id) = 0
                        
                            insert into 
                                db_sys.team_notification_auditLog (tnl_ID, tnc_ID) 
                            values 
                                (@tnl_ID,@tnc_id)
                
                    end
			
            end


		if @bodySource is not null and @bodySourceCHK = 0

			begin

            set @place_holder = newid() --

			set @body = 'There is an alert which refers to an invalid table or view. <p> The invalid table/view name is: <b>' + @bodySource + '</b>. Alert subject is: <b>' + @subject + '</b>.<p>'

            insert into db_sys.team_notification_log (auditLog_ID, ens_ID, message_subject, place_holder)
            values (@auditLog_ID, @notifications_schedule_ID, @subject, @place_holder)

            select @tnl_ID = ID from db_sys.team_notification_log tnl where place_holder = @place_holder

            set @body = concat(@body,'<p style="font-size:8px; ">',@tnl_ID,'</p>')

            update db_sys.team_notification_log set message_body = @body where ID = @tnl_ID

            if (select isnull(sum(1),0) from db_sys.team_notification_auditLog where tnl_ID = @tnl_ID and tnc_ID = 6) = 0 insert into db_sys.team_notification_auditLog (tnl_ID, tnc_ID) values (@tnl_ID, 6)

			end

end
GO
