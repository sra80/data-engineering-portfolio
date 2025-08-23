create or alter procedure [ext].[sp_Staff_Discount_Monitor]

as

/*
 Description:		Monitors for activity on staff discount codes that is considered out of the norm
 Project:			112
 Creator:			Shaun Edwards(SE)
 Copyright:			CompanyX Limited, 2021
MOD	DATE	INITS	COMMENTS
00  211120  SE      Created
01  211125  SE      Changed data source from dbo sales tables to ext sales table for optimisation
02  211210  SE      h.[Sales Order Status] = 1 added as no longer filtered in ext.sp_sales
03  220207  SE      Increase discount threshold for a single order to £300
04  220222  SE      Add media code description to 7 day window alerts
05  220308  SE      Change cursor name from x to [19cca154-ebe4-45c3-8c5d-22882bae93e2], change 2nd cursor name from y to [56a26f45-4721-4e5b-9e99-faee87159de5]
06  221128  SE      Add auditLog_ID traceability
07  230829  SE      Add team alert to HR
08  231020  SE      Add team alert to BI
09  231030  SE      Rem team alert fm BI
10  230930  SE      Move to multi-company (but also filter to UK only), exclude SHOP sales from mismatch reports
*/

set nocount on

declare @auditlog_ID int, @place_holder uniqueidentifier 

select @place_holder = place_holder from db_sys.procedure_schedule where replace(replace(procedureName,'[',''),']','') = 'ext.sp_Staff_Discount_Monitor'

select @auditlog_ID = ID from db_sys.auditLog where upper(eventDetail) = upper(@place_holder)

declare @cus nvarchar(32), @ordRef nvarchar(32), @ordDate date, @ordVal money, @disVal money, @media_code nvarchar(32), @currency_factor float, @cus_name nvarchar(max), @cus_type nvarchar(32), @media_descr nvarchar(max), @match_score int
declare @line_doc_type int, @line_doc_no_occ int, @line_version int

declare [19cca154-ebe4-45c3-8c5d-22882bae93e2] cursor for
    select
        h.[Sell-to Customer No_],
        h.No_,
        h.[Order Date],
        h.[Media Code],
        h.[Currency Factor],
        m.[Description],
        h.[Document Type],
        0 line_doc_no_occ,
        0 line_version,
        0 ordVal,
        0 disVal,
        c.[Name]
    from
        ext.Sales_Header h
    join
        [hs_consolidated].[Media Code] m
     on
        (
            h.company_id = m.company_id
        and h.[Media Code] = m.[Code]
        and m.[Audience] = 'STAFF'
        )
    join
        hs_consolidated.Customer c
    on 
        (
            h.company_id = c.company_id
        and h.[Sell-to Customer No_] = c.No_
        )
    where
        (
            h.No_ not in (select order_ref from ext.Staff_Discount_Monitor)
        and h.company_id = 1
        and patindex('TEST',c.[Customer Type]) = 0
        and h.[Sales Order Status] = 1
        )

    union 

    select
        h.[Sell-to Customer No_],
        h.No_,
        h.[Order Date],
        h.[Media Code],
        h.[Currency Factor],
        m.[Description],
        h.[Document Type],
        h.[Doc_ No_ Occurrence] line_doc_no_occ,
        h.[Version No_] line_version,
        0 ordVal,
        0 disVal,
        c.[Name]
    from
        ext.Sales_Header_Archive h
    join
        [hs_consolidated].[Media Code] m
     on
        (
            h.company_id = m.company_id
        and h.[Media Code] = m.[Code]
        and m.[Audience] = 'STAFF'
        )
    join
        hs_consolidated.Customer c
    on 
        (
            h.company_id = c.company_id
        and h.[Sell-to Customer No_] = c.No_
        )
    where
        (
            h.company_id = 1
        and h.[Order Date] >= dateadd(month,-2,convert(date,getutcdate()))
        and h.No_ not in (select order_ref from ext.Staff_Discount_Monitor)
        and patindex('TEST',c.[Customer Type]) = 0
        )

open [19cca154-ebe4-45c3-8c5d-22882bae93e2]

fetch next from [19cca154-ebe4-45c3-8c5d-22882bae93e2] into @cus, @ordRef, @ordDate, @media_code, @currency_factor, @media_descr, @line_doc_type, @line_doc_no_occ, @line_version, @ordVal, @disVal, @cus_name

while @@fetch_status = 0

begin

if @currency_factor <= 0 set @currency_factor = 1

select @ordVal += isnull(sum(l.[Amount Including VAT])/@currency_factor,0), @disVal += isnull(sum(l.[Line Discount Amount])/@currency_factor,0) from ext.Sales_Line l where l.company_id = 1 and l.[Document No_] = @ordRef and l.[Document Type] = @line_doc_type

select @ordVal += isnull(sum(l.[Amount Including VAT])/@currency_factor,0), @disVal += isnull(sum(l.[Line Discount Amount])/@currency_factor,0) from ext.Sales_Line_Archive l where l.company_id = 1 and l.[Document No_] = @ordRef and l.[Document Type] = @line_doc_type and l.[Doc_ No_ Occurrence] = @line_doc_no_occ and l.[Version No_] = @line_version

select
    @match_score = isnull(sum(1),0)
from
    string_split(@cus_name,' ') c
join
    string_split(@media_descr,' ') o
on
    (
        left(lower(c.[value]),4) = left(lower(o.value),4)
    
    )

insert into ext.Staff_Discount_Monitor (order_ref, order_date, discount_code, discount_amount, match_score) values (@ordRef, @ordDate, @media_code, @disVal, @match_score)

declare @email_to nvarchar(max) = '', @email_cc nvarchar(max) = '', @email_body nvarchar(max)

    select @email_to += case when len(@email_to) = 0 then '' else ';' end + email_address from db_sys.email_notifications_recipients where tag = 'staff_discount_monitor' and is_inactive = 0 and to_cc = 'to'

    select @email_cc += case when len(@email_cc) = 0 then '' else ';' end + email_address from db_sys.email_notifications_recipients where tag = 'staff_discount_monitor' and is_inactive = 0 and to_cc = 'cc'

if @match_score = 0 and @disVal < 200 and @cus != 'SHOP'

    begin

    set @email_body = 'There is a mismatch between the name on a staff discount code and an order recently placed, this is looking at the customer details and not the shipping details.<p>'
    set @email_body += 'Further information as follows:'
    set @email_body += '<ul>'
    set @email_body += '<li>Discount Code: ' + @media_code + ' (' + @media_descr + ')</li>'
    set @email_body += '<li>Customer Code: ' + @cus + ' (' + @cus_name + ')</li>'
    set @email_body += '<li>Order Reference: ' + @ordRef + '</li>'
    set @email_body += '<li>Order Value: £' + format(@ordVal,'###,##0.00') + ' (Discount: £' + format(@disVal,'###,##0.00') + ')</li>'
    set @email_body += '</ul>'

    update ext.Staff_Discount_Monitor set last_alert = getutcdate() where order_ref = @ordRef

    exec db_sys.sp_email_notifications @to = @email_to, @cc = @email_cc, @subject = 'Suspicious Activity on Staff Discount Code', @bodyIntro = @email_body, @importance = 'High', @auditLog_ID = @auditlog_ID

    exec db_sys.sp_email_notifications @subject = 'Suspicious Activity on Staff Discount Code', @bodyIntro = @email_body, @auditLog_ID = @auditlog_ID, @is_team_alert = 1, @tnc_id = 3

    -- exec db_sys.sp_email_notifications @subject = 'Suspicious Activity on Staff Discount Code', @bodyIntro = @email_body, @auditLog_ID = @auditlog_ID, @is_team_alert = 1, @tnc_id = 6

    end

if @disVal >= 300

    begin
    
    set @email_body = 'Staff discount on a recently placed order is higher than normally expected, total discount given was £' + format(@disVal,'###,##0.00') + '.<p>'
    set @email_body += 'Further information as follows:'
    set @email_body += '<ul>'
    set @email_body += '<li>Discount Code: ' + @media_code + ' (' + @media_descr + ')</li>'
    set @email_body += '<li>Customer Code: ' + @cus + ' (' + @cus_name + ')</li>'
    set @email_body += '<li>Order Reference: ' + @ordRef + '</li>'
    set @email_body += '<li>Order Value: £' + format(@ordVal,'###,##0.00') + ' (Discount: £' + format(@disVal,'###,##0.00') + ')</li>'
    set @email_body += '</ul>'

    update ext.Staff_Discount_Monitor set last_alert = getutcdate() where order_ref = @ordRef

    exec db_sys.sp_email_notifications @to = @email_to, @cc = @email_cc, @subject = 'Suspicious Activity on Staff Discount Code', @bodyIntro = @email_body, @importance = 'High', @auditLog_ID = @auditlog_ID

    exec db_sys.sp_email_notifications @subject = 'Suspicious Activity on Staff Discount Code', @bodyIntro = @email_body, @auditLog_ID = @auditlog_ID, @is_team_alert = 1, @tnc_id = 3

    -- exec db_sys.sp_email_notifications @subject = 'Suspicious Activity on Staff Discount Code', @bodyIntro = @email_body, @auditLog_ID = @auditlog_ID, @is_team_alert = 1, @tnc_id = 6

    end

fetch next from [19cca154-ebe4-45c3-8c5d-22882bae93e2] into @cus, @ordRef, @ordDate, @media_code, @currency_factor, @media_descr, @line_doc_type, @line_doc_no_occ, @line_version, @ordVal, @disVal, @cus_name

end

close [19cca154-ebe4-45c3-8c5d-22882bae93e2]
deallocate [19cca154-ebe4-45c3-8c5d-22882bae93e2]

set @media_descr = null

declare @discount_code nvarchar(32), @last_order_date date, @last_order_ref nvarchar(32), @total_discount money, @total_orders int, @last_alert date

declare [56a26f45-4721-4e5b-9e99-faee87159de5] cursor for
select 
    m.discount_code,
    m.order_ref,
    o.m,
    q.total_discount,
    q.total_orders
from 
    ext.Staff_Discount_Monitor m 
cross apply 
    (
        select max(order_date) m from ext.Staff_Discount_Monitor n where m.discount_code = n.discount_code
    ) o
cross apply
    (
        select sum(discount_amount) total_discount, sum(1) total_orders from ext.Staff_Discount_Monitor p where m.discount_code = p.discount_code and p.order_date >= dateadd(day,-7,m.order_date)
    ) q
cross apply
    (
        select max(order_ref) order_ref from ext.Staff_Discount_Monitor r where m.discount_code = r.discount_code and m.order_date  = r.order_date
    ) s
where
    (
        m.order_date = o.m
    and m.order_ref = s.order_ref
    and
        (
            q.total_discount > 300
        or  q.total_orders > 5
        )
    )

open [56a26f45-4721-4e5b-9e99-faee87159de5]

fetch next from [56a26f45-4721-4e5b-9e99-faee87159de5] into @discount_code, @last_order_ref, @last_order_date, @total_discount, @total_orders

while @@fetch_status = 0

begin

select @last_alert = max(last_alert) from ext.Staff_Discount_Monitor where discount_code = @discount_code

if @total_discount >= 300 and (@last_alert is null or @last_order_date > @last_alert)

    begin

    select @media_descr = [Description] from [hs_consolidated].[Media Code] where company_id = 1 and [Code] = @discount_code

    set @email_body = 'Staff discount on code <b>' + @discount_code + ' (' + @media_descr + ')</b> over the past 7 days has been higher than normally expected, total discount so far is £' + format(@total_discount,'###,##0.00') + '.'

    update ext.Staff_Discount_Monitor set last_alert = getutcdate() where order_ref = @last_order_ref 

    exec db_sys.sp_email_notifications @to = @email_to, @cc = @email_cc, @subject = 'Suspicious Activity on Staff Discount Code', @bodyIntro = @email_body, @importance = 'High', @auditLog_ID  = @auditlog_ID

    exec db_sys.sp_email_notifications @subject = 'Suspicious Activity on Staff Discount Code', @bodyIntro = @email_body, @auditLog_ID = @auditlog_ID, @is_team_alert = 1, @tnc_id = 3

    -- exec db_sys.sp_email_notifications @subject = 'Suspicious Activity on Staff Discount Code', @bodyIntro = @email_body, @auditLog_ID = @auditlog_ID, @is_team_alert = 1, @tnc_id = 6

    set @media_descr = null

    end

if @total_orders > 5 and @total_discount < 300 and (@last_alert is null or @last_order_date > @last_alert)

    begin

    select @media_descr = [Description] from [hs_consolidated].[Media Code] where company_id = 1 and [Code] = @discount_code

    set @email_body = 'Over the 7 days, there have been a higher than normal number of orders placed on staff discount code <b>' + @discount_code + ' (' + @media_descr + ')</b>. ' + format(@total_orders,'###,##0') + ' orders have been placed in this time.'

    update ext.Staff_Discount_Monitor set last_alert = getutcdate() where order_ref = @last_order_ref

    exec db_sys.sp_email_notifications @to = @email_to, @cc = @email_cc, @subject = 'Suspicious Activity on Staff Discount Code', @bodyIntro = @email_body, @importance = 'High', @auditLog_ID = @auditlog_ID

    exec db_sys.sp_email_notifications @subject = 'Suspicious Activity on Staff Discount Code', @bodyIntro = @email_body, @auditLog_ID = @auditlog_ID, @is_team_alert = 1, @tnc_id = 3

    -- exec db_sys.sp_email_notifications @subject = 'Suspicious Activity on Staff Discount Code', @bodyIntro = @email_body, @auditLog_ID = @auditlog_ID, @is_team_alert = 1, @tnc_id = 6

    set @media_descr = null

    end

fetch next from [56a26f45-4721-4e5b-9e99-faee87159de5] into @discount_code, @last_order_ref, @last_order_date, @total_discount, @total_orders

end

close [56a26f45-4721-4e5b-9e99-faee87159de5]
deallocate [56a26f45-4721-4e5b-9e99-faee87159de5]
GO
