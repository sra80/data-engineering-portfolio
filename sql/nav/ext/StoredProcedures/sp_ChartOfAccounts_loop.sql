SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create or alter procedure [ext].[sp_ChartOfAccounts_loop]

as

/*
 Description:		Executes [ext].[ChartOfAccounts] sp and set timestamps for G_L Entry tables
 Project:			135
 Creator:			Ana Jurkic (AJ)
 Copyright:			CompanyX Limited, 2021
MOD	DATE	INITS	COMMENTS
07			AJ		Added @HSBV_timestamp_begin and @HSBV_timestamp_end
					Changed from @eventVersion = '00' to  @eventVersion = '07'
					Added insert to @table_ChartOfAccounts for NL transactions
					Commented out insert into tmp.sp_ChartOfAccounts_loop_audit & droppped the table
08			AJ		Added new GLs change tracking
09			AJ		Added new GL change tracking
10			AJ		Added @QCAL_timestamp_begin and @QCAL_timestamp_end
					Added insert to @table_ChartOfAccounts for QC
					Added update for @QCAL_timestamp_end
					Changed from @eventVersion = '07' to  @eventVersion = '10'
11			AJ		Added 40505 to change tracking
12	220719	AJ		Added 50120 to change tracking
13	221114	AJ		Added 82570, 82580 & 82590 to change tracking
14	230103	AJ		Added 40507, 40509, 50107, 50109 to change tracking
15	230116	AJ		Added 72230 to change tracking
16	230124	AJ		Added @HSNZ_timestamp_begin and @HSNZ_timestamp_end
					Added insert to @table_ChartOfAccounts for HSNZ transactions
					Added update for @HSNZ_timestamp_end
					Added @begin variable
17	230127	AJ		Added 87580 and 99080 to change tracking
18	230401	AJ		Added @HSIE_timestamp_begin and @HSIE_timestamp_end
					Added insert to @table_ChartOfAccounts for HSIE transactions
					Added update for @HSIE_timestamp_end
19	230330	AJ		Added 40510, 50112, 50114, 50115 to change tracking
20	230405	AJ		Added 50110 to change tracking
21	230627	AJ		Added 99500 to change tracking
22	231202	AJ		Added 40501, 50101 and 50111 to change tracking
23	240201	AJ		Removed 50112, 50114, 50115 from change tracking
24	240227	AJ		Added 73100 to change tracking
25	240311	AJ		Added 82100 to change tracking
26  240430  AJ      Change made to use Entry No instead of timestamp to identify new records since the last run
27  240830  AJ      Added 40504 and 50104 to change tracking
28	241129	AJ		Modified select for entry_end variables to exclude close income transactions (where convert(time(0),[Posting Date]) = '00:00:00')
29  241129  AJ      Added 40503 and 40506 to change tracking
30  250415  AJ      Corrected reference to @HSNZ_entry_begin with @HSIE_entry_begin for HSIE insert into @table_ChartOfAccounts
					Replaced reference to @begin with getdate()

!!! Remeber to change @eventVersion !!!

*/

set nocount on

-- changed [Posting Date] <= eomonth(dateadd(month,-1,getdate())) to [Posting Date] <= eomonth(dateadd(month,0,getdate()))

declare /*@row_count int = 1,*/ @place_holder nvarchar(36), @auditLog_ID int, @out_of_schedule bit = 0

select top 1 @place_holder = place_holder from db_sys.procedure_schedule where procedureName = '[ext].[sp_ChartOfAccounts_loop]'

select top 1 @auditLog_ID = ID from db_sys.auditLog where eventDetail = @place_holder

if @auditLog_ID is null -- @auditLog_ID will only be null if sp is running out of schedule 
	
	begin 
		set @place_holder = NEWID() 
		exec db_sys.sp_auditLog_start @eventType = 'Procedure', @eventName = '[ext].[sp_ChartOfAccounts_loop]', @eventVersion = '30', @placeHolder = @place_holder 
		select @auditLog_ID = ID from db_sys.auditLog where eventDetail = @place_holder
		set @out_of_schedule = 1
	end

--26
-- declare @timestamp_begin varbinary(8), @timestamp_end varbinary(8), @gl nvarchar(32), @CE_timestamp_begin varbinary(8), @CE_timestamp_end varbinary(8), @HSBV_timestamp_begin varbinary(8), @HSBV_timestamp_end varbinary(8), @QCAL_timestamp_begin varbinary(8), @QCAL_timestamp_end varbinary(8), @HSNZ_timestamp_begin varbinary(8), @HSNZ_timestamp_end varbinary(8), @HSIE_timestamp_begin varbinary(8), @HSIE_timestamp_end varbinary(8)
--26
declare @entry_begin varbinary(8), @entry_end varbinary(8), @gl nvarchar(32), @CE_entry_begin varbinary(8), @CE_entry_end varbinary(8), @HSBV_entry_begin varbinary(8), @HSBV_entry_end varbinary(8), @QCAL_entry_begin varbinary(8), @QCAL_entry_end varbinary(8), @HSNZ_entry_begin varbinary(8), @HSNZ_entry_end varbinary(8), @HSIE_entry_begin varbinary(8), @HSIE_entry_end varbinary(8)


declare @table_ChartOfAccounts ext.ty_ChartOfAccounts
--26
/*
select @timestamp_begin = last_timestamp from db_sys.timestamp_tracker where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = 'dbo.G_L_Entry'

select @timestamp_end = max([timestamp]) from dbo.G_L_Entry

select @CE_timestamp_begin = last_timestamp from db_sys.timestamp_tracker where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[CE$G_L Entry]'

select @CE_timestamp_end = max([timestamp]) from [dbo].[CE$G_L Entry]

select @HSBV_timestamp_begin = last_timestamp from db_sys.timestamp_tracker where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[NL$G_L Entry]'

select @HSBV_timestamp_end = max([timestamp]) from [dbo].[NL$G_L Entry]

--10
select @QCAL_timestamp_begin = last_timestamp from db_sys.timestamp_tracker where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[QC$G_L Entry]'

select @QCAL_timestamp_end = max([timestamp]) from [dbo].[QC$G_L Entry]

--16
select @HSNZ_timestamp_begin = last_timestamp from db_sys.timestamp_tracker where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[NZ$G_L Entry]' 

select @HSNZ_timestamp_end = max([timestamp]) from [dbo].[NZ$G_L Entry]


--18
select @HSIE_timestamp_begin = last_timestamp from db_sys.timestamp_tracker where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[IE$G_L Entry]' 

select @HSIE_timestamp_end = max([timestamp]) from [dbo].[IE$G_L Entry]
*/

--26
select @entry_begin = last_entry from db_sys.entry_no_tracker where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = 'dbo.G_L_Entry'
--28
select @entry_end = max([Entry No_]) from dbo.G_L_Entry where convert(time(0),[Posting Date]) = '00:00:00'


select @CE_entry_begin = last_entry from db_sys.entry_no_tracker where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[CE$G_L Entry]'
--28
select @CE_entry_end = max([Entry No_]) from [dbo].[CE$G_L Entry] where convert(time(0),[Posting Date]) = '00:00:00'


select @HSBV_entry_begin = last_entry from db_sys.entry_no_tracker where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[NL$G_L Entry]'
--28
select @HSBV_entry_end = max([Entry No_]) from [dbo].[NL$G_L Entry] where convert(time(0),[Posting Date]) = '00:00:00'


select @QCAL_entry_begin = last_entry from db_sys.entry_no_tracker where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[QC$G_L Entry]'
--28
select @QCAL_entry_end = max([Entry No_]) from [dbo].[QC$G_L Entry] where convert(time(0),[Posting Date]) = '00:00:00'


select @HSNZ_entry_begin = last_entry from db_sys.entry_no_tracker where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[NZ$G_L Entry]' 
--28
select @HSNZ_entry_end = max([Entry No_]) from [dbo].[NZ$G_L Entry] where convert(time(0),[Posting Date]) = '00:00:00'


select @HSIE_entry_begin = last_entry from db_sys.entry_no_tracker where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[IE$G_L Entry]' 
--28
select @HSIE_entry_end = max([Entry No_]) from [dbo].[IE$G_L Entry] where convert(time(0),[Posting Date]) = '00:00:00'

--16
declare @begin date = datefromparts(year(getutcdate())-1,1,1) if month(/*@begin --30*/getdate()) = 1 set @begin = dateadd(year,-1,@begin)

--26
/*
--UK
insert into @table_ChartOfAccounts (period_date,gl)
select datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_] from dbo.G_L_Entry where [Posting Date] >= @begin /*datefromparts(year(getdate())-1,1,1) --16*/ and [Posting Date] <= eomonth(dateadd(month,0,getdate())) and [timestamp] > @timestamp_begin and [timestamp] <= @timestamp_end group by datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_]

--Group Eliminations
insert into @table_ChartOfAccounts (period_date,gl)
select datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_] from [dbo].[CE$G_L Entry] ce where [Posting Date] >= @begin /*datefromparts(year(getdate())-1,1,1) --16*/ and [Posting Date] <= eomonth(dateadd(month,0,getdate())) and [timestamp] > @CE_timestamp_begin and [timestamp] <= @CE_timestamp_end and not exists (select 1 from @table_ChartOfAccounts c where datefromparts(year(ce.[Posting Date]),month(ce.[Posting Date]),1) = c.period_date and ce.[G_L Account No_] = c.gl) group by datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_]

--07
--NL
insert into @table_ChartOfAccounts (period_date,gl)
select datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_] from [dbo].[NL$G_L Entry] NL where [Posting Date] >= @begin /*datefromparts(year(getdate())-1,1,1) --16*/ and [Posting Date] <= eomonth(dateadd(month,0,getdate())) and [timestamp] > @HSBV_timestamp_begin and [timestamp] <= @HSBV_timestamp_end and not exists (select 1 from @table_ChartOfAccounts c where datefromparts(year(NL.[Posting Date]),month(NL.[Posting Date]),1) = c.period_date and NL.[G_L Account No_] = c.gl) group by datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_]

--10
--QC
insert into @table_ChartOfAccounts (period_date,gl)
select datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_] from [dbo].[QC$G_L Entry] qcal where [Posting Date] >= @begin /*datefromparts(year(getdate())-1,1,1) --16*/ and [Posting Date] <= eomonth(dateadd(month,0,getdate())) and [timestamp] > @QCAL_timestamp_begin and [timestamp] <= @QCAL_timestamp_end and not exists (select 1 from @table_ChartOfAccounts c where datefromparts(year(qcal.[Posting Date]),month(qcal.[Posting Date]),1) = c.period_date and qcal.[G_L Account No_] = c.gl) group by datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_]

--16
--HSNZ
insert into @table_ChartOfAccounts (period_date,gl)
select datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_] from [dbo].[NZ$G_L Entry] hsnz where [Posting Date] >= @begin /*datefromparts(year(getdate())-1,1,1) --16*/ and [Posting Date] <= eomonth(dateadd(month,0,getdate())) and [timestamp] > @HSNZ_timestamp_begin and [timestamp] <= @HSNZ_timestamp_end and not exists (select 1 from @table_ChartOfAccounts c where datefromparts(year(hsnz.[Posting Date]),month(hsnz.[Posting Date]),1) = c.period_date and hsnz.[G_L Account No_] = c.gl) group by datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_]

--18
--HSIE
insert into @table_ChartOfAccounts (period_date,gl)
select datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_] from [dbo].[IE$G_L Entry] hsie where [Posting Date] >= @begin and [Posting Date] <= eomonth(dateadd(month,0,getdate())) and [timestamp] > @HSNZ_timestamp_begin and [timestamp] <= @HSIE_timestamp_end and not exists (select 1 from @table_ChartOfAccounts c where datefromparts(year(hsie.[Posting Date]),month(hsie.[Posting Date]),1) = c.period_date and hsie.[G_L Account No_] = c.gl) group by datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_]
*/

--26
--UK
insert into @table_ChartOfAccounts (period_date,gl)
select datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_] from dbo.G_L_Entry where [Posting Date] >= @begin /*datefromparts(year(getdate())-1,1,1) --16*/ and [Posting Date] <= eomonth(dateadd(month,0,getdate())) and [Entry No_] > @entry_begin and [Entry No_] <= @entry_end group by datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_]

--Group Eliminations
insert into @table_ChartOfAccounts (period_date,gl)
select datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_] from [dbo].[CE$G_L Entry] ce where [Posting Date] >= @begin /*datefromparts(year(getdate())-1,1,1) --16*/ and [Posting Date] <= eomonth(dateadd(month,0,getdate())) and [Entry No_] > @CE_entry_begin and [Entry No_] <= @CE_entry_end and not exists (select 1 from @table_ChartOfAccounts c where datefromparts(year(ce.[Posting Date]),month(ce.[Posting Date]),1) = c.period_date and ce.[G_L Account No_] = c.gl) group by datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_]

--NL
insert into @table_ChartOfAccounts (period_date,gl)
select datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_] from [dbo].[NL$G_L Entry] NL where [Posting Date] >= @begin /*datefromparts(year(getdate())-1,1,1) --16*/ and [Posting Date] <= eomonth(dateadd(month,0,getdate())) and [Entry No_] > @HSBV_entry_begin and [Entry No_] <= @HSBV_entry_end and not exists (select 1 from @table_ChartOfAccounts c where datefromparts(year(NL.[Posting Date]),month(NL.[Posting Date]),1) = c.period_date and NL.[G_L Account No_] = c.gl) group by datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_]

--QC
insert into @table_ChartOfAccounts (period_date,gl)
select datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_] from [dbo].[QC$G_L Entry] qcal where [Posting Date] >= @begin /*datefromparts(year(getdate())-1,1,1) --16*/ and [Posting Date] <= eomonth(dateadd(month,0,getdate())) and [Entry No_] > @QCAL_entry_begin and [Entry No_] <= @QCAL_entry_end and not exists (select 1 from @table_ChartOfAccounts c where datefromparts(year(qcal.[Posting Date]),month(qcal.[Posting Date]),1) = c.period_date and qcal.[G_L Account No_] = c.gl) group by datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_]

--HSNZ
insert into @table_ChartOfAccounts (period_date,gl)
select datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_] from [dbo].[NZ$G_L Entry] hsnz where [Posting Date] >= @begin /*datefromparts(year(getdate())-1,1,1) --16*/ and [Posting Date] <= eomonth(dateadd(month,0,getdate())) and [Entry No_] > @HSNZ_entry_begin and [Entry No_] <= @HSNZ_entry_end and not exists (select 1 from @table_ChartOfAccounts c where datefromparts(year(hsnz.[Posting Date]),month(hsnz.[Posting Date]),1) = c.period_date and hsnz.[G_L Account No_] = c.gl) group by datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_]

--HSIE
insert into @table_ChartOfAccounts (period_date,gl)
select datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_] from [dbo].[IE$G_L Entry] hsie where [Posting Date] >= @begin and [Posting Date] <= eomonth(dateadd(month,0,getdate())) and [Entry No_] > /*@HSNZ_entry_begin*/@HSIE_entry_begin and [Entry No_] <= @HSIE_entry_end and not exists (select 1 from @table_ChartOfAccounts c where datefromparts(year(hsie.[Posting Date]),month(hsie.[Posting Date]),1) = c.period_date and hsie.[G_L Account No_] = c.gl) group by datefromparts(year([Posting Date]),month([Posting Date]),1), [G_L Account No_]



----added to insert dates for 'MA10000','MA10001','MA10002','MA10003','MA10004','MA10005','MA10006','MA10008'
--08 -- added 40502, 50102, 99060
--09 -- added 96400
--11 -- added 40505
--11 added group by period_date for 2 top if statements below due to PK violation
--12 --added 50120
--13 --added 82570 & 82580 & 82590
--14 --added 40507, 40509, 50107, 50109
--15 --added 72230
--16 -- added 87580 and 99080
--19 --Added 40510, 50112, 50114, 50115, MA10009, MA10010 to change tracking
--20 --Added 50110 to change tracking	
--22 Added 40501, 50101 and 50111 to change tracking
--23 Removed 50112, 50114, 50115 from change tracking
--24 Added 73100 to change tracking
--27 -- added 40504 and 50104
--29 --added 40503  and 40506

if(select sum(1) from @table_ChartOfAccounts where gl in ('40500','40501','40502','40503','40504','40505','40506','40507','40509','43550','43500','40510')) > 0 insert into @table_ChartOfAccounts (period_date, gl) select period_date, 'MA10009' from @table_ChartOfAccounts where gl in ('40500','40501','40502','40503','40504','40505','40506','40507','40509','43550','43500','40510') group by period_date
if(select sum(1) from @table_ChartOfAccounts where gl in ('40500','40501','40502','40503','40504','40505','40506','40507','40509')) > 0 insert into @table_ChartOfAccounts (period_date, gl) select period_date, 'MA10000' from @table_ChartOfAccounts where gl in ('40500','40501','40502','40503','40504','40505','40506','40507','40509') group by period_date
if(select sum(1) from  @table_ChartOfAccounts where gl in ('40500','40501','40502','40503','40504','40505','40506','40507','40509')) > 0 insert into @table_ChartOfAccounts (period_date, gl) select period_date, 'MA10001' from  @table_ChartOfAccounts where gl in ('40500','40501','40502','40503','40504','40505','40506','40507','40509') group by period_date
if(select sum(1) from  @table_ChartOfAccounts where gl in ('40500','40501','40502','40503','40504','40505','40506','40507','40509','43550','43500','40510')) > 0 insert into @table_ChartOfAccounts (period_date, gl) select period_date, 'MA10002' from  @table_ChartOfAccounts where gl in ('40500','40501','40502','40503','40504','40505','40506','40507','40509','43550','43500','40510')  group by period_date
if(select sum(1) from  @table_ChartOfAccounts where gl in ('50100','50101','50102','50104','50107','50109','50120','50150','50180','50530','50540','52050','50110','50111')) > 0 insert into @table_ChartOfAccounts (period_date, gl) select period_date, 'MA10010' from  @table_ChartOfAccounts where gl  in ('50100','50101','50102','50104','50107','50109','50120','50150','50180','50530','50540','52050','50110','50111') group by period_date
if(select sum(1) from  @table_ChartOfAccounts where gl in ('40500','40501','40502','40503','40504','40505','40506','40507','40509','43550','43500','40510','50100','50101','50102','50104','50107','50109','50120','50150','50180','50530','50540','52050','50110','50111')) > 0 insert into @table_ChartOfAccounts (period_date, gl) select period_date, 'MA10003' from  @table_ChartOfAccounts where gl  in ('40500','40501','40502','40503','40504','40505','40506','40507','40509','43550','43500','40510','50100','50101','50102','50104','50107','50109','50120','50150','50180','50530','50540','52050','50110','50111') group by period_date
if(select sum(1) from  @table_ChartOfAccounts where gl in ('56000','56510','57510','57350','57600','58060','53000')) > 0 insert into @table_ChartOfAccounts (period_date, gl) select period_date, 'MA10004' from  @table_ChartOfAccounts where gl  in ('56000','56510','57510','57350','57600','58060','53000') group by period_date
if(select sum(1) from  @table_ChartOfAccounts where gl in ('40500','40501','40502','40503','40504','40505','40506','40507','40509','43550','43500','40510','50100','50101','50102','50104','50107','50109','50120','50150','50180','50530','50540','52050','50110','50111','56000','56510','57510','57350','57600','58060','53000')) > 0 insert into @table_ChartOfAccounts (period_date, gl) select period_date, 'MA10005' from  @table_ChartOfAccounts where gl  in ('40500','40501','40502','40503','40504','40505','40506','40507','40509','43550','43500','40510','50100','50101','50102','50104','50107','50109','50120','50150','50180','50530','50540','52050','50110','50111','56000','56510','57510','57350','57600','58060','53000')  group by period_date
if(select sum(1) from  @table_ChartOfAccounts where gl in ('71500','71510','72550','71550','73000','73010','73040','73050','73060','73100','73530','81500','57000','67940','67920','81510','75720','75790','75800','75810','75730','75770','75870','75130','75170','75180','75610','75750','75880','75630','75830','75140','75150','75160','75840','75110','75120','75650','75660','75670','75680','81590','81600','71570','71610','75950','75190','75200','81530','81910','74550','74600','73520','71600','81810','73540','81560','71620','75820','81580','99500','99550','72220','72230','72300','81550','81450','83150','83550','71590','81540','82010','82100','82150','98050','98060','87580','99080','83050','97550','82510','82520','82530','82540','82550','82570','82580','82590')) > 0 insert into @table_ChartOfAccounts (period_date, gl) select period_date, 'MA10006' from  @table_ChartOfAccounts where gl  in ('71500','71510','72550','71550','73000','73010','73040','73050','73060','73100','73530','81500','57000','67940','67920','81510','75720','75790','75800','75810','75730','75770','75870','75130','75170','75180','75610','75750','75880','75630','75830','75140','75150','75160','75840','75110','75120','75650','75660','75670','75680','81590','81600','71570','71610','75950','75190','75200','81530','81910','74550','74600','73520','71600','81810','73540','81560','71620','75820','81580','99500','99550','72220','72230','72300','81550','81450','83150','83550','71590','81540','82010','82100','82150','98050','98060','87580','99080','83050','97550','82510','82520','82530','82540','82550','82570','82580','82590') group by period_date
if(select sum(1) from  @table_ChartOfAccounts where gl in ('40500','40501','40502','40503','40504','40505','40506','40507','40509','43550','43500','40510','50100','50101','50102','50104','50107','50109','50120','50150','50180','50530','50540','52050','50110','50111','56000','56510','57510','57350','57600','58060','53000','67100','67130','67160','67240','67270','67290','67310','67330','67350','67370','67390','67410','67420','67430','67450','67460','67520','67540','67570','67610','67640','67660','67710','67730','67760','67800','67830','67860','69000','69030','69040','69100','69110','69130','69200','69210','69220','69230','69240','69250','69310','69330','69340','69410','69420','69440','69450','69460','69470','69510','69520','69530','69540','69600','69620','69700','69720','69730','71500','71510','72550','71550','73000','73010','73040','73050','73060','73100','73530','81500','57000','67940','67920','81510','75720','75790','75800','75810','75730','75770','75870','75130','75170','75180','75610','75750','75880','75630','75830','75140','75150','75160','75840','75110','75120','75650','75660','75670','75680','81590','81600','71570','71610','75950','75190','75200','81530','81910','74550','74600','73520','71600','81810','73540','81560','71620','75820','81580''99500','99550','72220','72230','72300','81550','81450','83150','83550','71590','81540','82010','82100','82150','98050','98060','87580','99080','83050','97550','82510','82520','82530','82540','82550','82570','82580','82590')) > 0 insert into @table_ChartOfAccounts (period_date, gl) select period_date, 'MA10007' from  @table_ChartOfAccounts where gl  in ('40500','40501','40502','40503','40504','40505','40506','40507','40509','43550','43500','40510','50100','50101','50102','50104','50107','50109','50120','50150','50180','50530','50540','52050','50110','50111','56000','56510','57510','57350','57600','58060','53000','67100','67130','67160','67240','67270','67290','67310','67330','67350','67370','67390','67410','67420','67430','67450','67460','67520','67540','67570','67610','67640','67660','67710','67730','67760','67800','67830','67860','69000','69030','69040','69100','69110','69130','69200','69210','69220','69230','69240','69250','69310','69330','69340','69410','69420','69440','69450','69460','69470','69510','69520','69530','69540','69600','69620','69700','69720','69730','71500','71510','72550','71550','73000','73010','73040','73050','73060','73100','73530','81500','57000','67940','67920','81510','75720','75790','75800','75810','75730','75770','75870','75130','75170','75180','75610','75750','75880','75630','75830','75140','75150','75160','75840','75110','75120','75650','75660','75670','75680','81590','81600','71570','71610','75950','75190','75200','81530','81910','74550','74600','73520','71600','81810','73540','81560','71620','75820','81580','99500','99550','72220','72230','72300','81550','81450','83150','83550','71590','81540','82010','82100','82150','98050','98060','87580','99080','83050','97550','82510','82520','82530','82540','82550','82570','82580','82590')  group by period_date
if(select sum(1) from  @table_ChartOfAccounts where gl in ('96400','96500','84520','84530','84550','85550','84510','84540','84560','87500','87510','87520','87540','87550','87560','87570','98550','99050','99060','88550','99070','98061','98062')) > 0 insert into @table_ChartOfAccounts (period_date, gl) select period_date, 'MA10008' from  @table_ChartOfAccounts where gl  in ('96500','84520','84530','84550','85550','84510','84540','84560','87500','87510','87520','87540','87550','87560','87570','98550','99050','99060','88550','99070','98061','98062') group by period_date


exec [ext].[sp_ChartOfAccounts] @table_ChartOfAccounts = @table_ChartOfAccounts

--select @row_count = sum(1) from @table_ChartOfAccounts

--26
/*

update db_sys.timestamp_tracker set last_timestamp = @timestamp_end, last_update = getutcdate() where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = 'dbo.G_L_Entry'

update db_sys.timestamp_tracker set last_timestamp = @CE_timestamp_end, last_update = getutcdate() where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[CE$G_L Entry]'

update db_sys.timestamp_tracker set last_timestamp = @HSBV_timestamp_end, last_update = getutcdate() where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[NL$G_L Entry]'

--10
update db_sys.timestamp_tracker set last_timestamp = @QCAL_timestamp_end, last_update = getutcdate() where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[QC$G_L Entry]'

--16
update db_sys.timestamp_tracker set last_timestamp = @HSNZ_timestamp_end, last_update = getutcdate() where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[NZ$G_L Entry]'

--18
update db_sys.timestamp_tracker set last_timestamp = /*isnull(*/@HSIE_timestamp_end/*,0)*/, last_update = getutcdate() where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[IE$G_L Entry]'
*/

--26

update db_sys.entry_no_tracker set last_entry = @entry_end, last_update = getutcdate() where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = 'dbo.G_L_Entry'

update db_sys.entry_no_tracker set last_entry = @CE_entry_end, last_update = getutcdate() where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[CE$G_L Entry]'

update db_sys.entry_no_tracker set last_entry = @HSBV_entry_end, last_update = getutcdate() where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[NL$G_L Entry]'

update db_sys.entry_no_tracker set last_entry = @QCAL_entry_end, last_update = getutcdate() where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[QC$G_L Entry]'

update db_sys.entry_no_tracker set last_entry = @HSNZ_entry_end, last_update = getutcdate() where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[NZ$G_L Entry]'

update db_sys.entry_no_tracker set last_entry = /*isnull(*/@HSIE_entry_end/*,0)*/, last_update = getutcdate() where stored_procedure = '[ext].[sp_ChartOfAccounts_loop]' and table_name = '[dbo].[IE$G_L Entry]'

--insert into tmp.sp_ChartOfAccounts_loop_audit (auditLog_ID,row_count) values (@auditLog_ID,@row_count)

if @out_of_schedule = 1 exec db_sys.sp_auditLog_end @placeHolder = @place_holder, @eventDetail = 'Procedure Outcome: Success'

GO