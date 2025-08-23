CREATE   procedure [ext].[sp_Customer_Type]

as

update
    other
set
    other.is_anon = hs_sell.is_anon,
    other.is_retailAcc = hs_sell.is_retailAcc
from
    (
        select
            nav_code,
            is_anon,
            is_retailAcc
        from
            ext.Customer_Type
        where
            company_id = 1
    ) hs_sell
join
    (
        select
            nav_code,
            is_anon,
            is_retailAcc
        from
            ext.Customer_Type
        where
            company_id > 1
    ) other
on
    (
        hs_sell.nav_code = other.nav_code
    )
where
    (
        hs_sell.is_anon != other.is_anon
    or  hs_sell.is_retailAcc != other.is_retailAcc
    )

--added by SE 2023-08-30 16:39:01.350 (UTC)
update
    ct
set
   ct.ID_grp = grp.ID_grp
from
    ext.Customer_Type ct
join
    hs_consolidated.[Customer Type] h_ct
on
    (
        ct.company_id = h_ct.company_id
    and ct.nav_code = h_ct.Code
    )
join
    (
        select
            min(ct.ID) ID_grp,
            h_ct.[Description]
        from
            ext.Customer_Type ct
        join
            hs_consolidated.[Customer Type] h_ct
        on
            (
                ct.company_id = h_ct.company_id
            and ct.nav_code = h_ct.Code
            )
        group by
            h_ct.[Description]
    ) grp
on
    (
        h_ct.[Description] = grp.[Description]
    )
where
    (
        ct.ID_grp is null
    or ct.ID_grp != grp.ID_grp
    )
    
/*
declare @count int

select @count = count(*) from ext.Customer_Type where convert(date,addedTSUTC) = convert(date,getutcdate())

if @count > 0

begin

declare @sub nvarchar(30)
declare @msg nvarchar(max)

set @msg = 'This message requires a response from a member of the Business Intelligence Team.<p>'

	if @count = 1 

	begin

	set @sub = 'NAV: New Customer Type'
	set @msg += 'The following customer type is new and has been recently added to NAV:<p> <ul style="padding-left:20px"> '

	end

	if @count > 1 
	
	begin
	
	set @sub = 'NAV: New Customer Types'
	set @msg += 'The following customer types are new and have recently been added to NAV:<p> <ul style="padding-left:20px"> '

	end

select @msg = @msg + '<li>' + nav_code + ' (' + (select NAV_DB from db_sys.Company c where Customer_Type.company_id = c.ID) + ')</li>' from ext.Customer_Type where convert(date,addedTSUTC) = convert(date,getutcdate()) order by company_id

set @msg = @msg + '</ul> <p>'

set @msg += 'By default, the anonymous flag (is_anon) has been set to TRUE, i.e. customer details are anonymised and the retail account flag (is_retailAcc) has been set to FALSE. Please amend ext.Customer_Type where necessary.'

	exec db_sys.sp_email_notifications
		 @to = 'user@example.com'
		,@subject = @sub
		,@bodyIntro = @msg
		
end
*/
GO
