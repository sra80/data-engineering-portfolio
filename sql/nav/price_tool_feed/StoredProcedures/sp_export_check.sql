create or alter procedure price_tool_feed.sp_export_check

as

set nocount on

update
    ip
set
    ip.is_in_HT = 1
from 
    price_tool_feed.import_pricelist ip
outer apply
    (
        select top 1
            external_id
        from
            price_tool_feed.import_pricelist pl
        where
            (
                ip.filelist_id = pl.filelist_id
            and ip.pricetype_id = pl.pricetype_id
            and ip.item_id = pl.item_id
            and ip.zone_id = pl.zone_id
            and ip.valid_from = pl.valid_from
            and ip.valid_to = pl.valid_to
            and lower(pl.external_id) in (select [External ID] from [UK$Sales Price Holding Table])
            )
    ) x
where 
    (
        x.external_id > 0x0
    and ip.is_in_HT = 0
    )

update
    ip_all
set
    ip_all.is_in_SP = 1,
    ip_all.is_in_next_post = case when ip.external_id = ip_all.external_id then 1 else 0 end
from
    price_tool_feed.import_pricelist ip
join
    price_tool_feed.import_pricelist ip_all
on
    (
        ip.filelist_id = ip_all.filelist_id
    and ip.pricetype_id = ip_all.pricetype_id
    and ip.item_id = ip_all.item_id
    and ip.zone_id = ip_all.zone_id
    and ip.price = ip_all.price
    and ip.valid_from = ip_all.valid_from
    and ip.valid_to = ip_all.valid_to
    )
where
    ip.id in
        (
            select
                ip.id
            from
                price_tool_feed.import_pricelist ip
            join
                [dbo].[UK$Sales Price] sp
            on
                (
                    ip.external_id = try_convert(uniqueidentifier,sp.[External ID])
                and ip.price = sp.[Unit Price]
                and price_tool_feed.fn_past_to_tomorrow(ip.valid_from,ip.addTS,1) = price_tool_feed.fn_past_to_tomorrow(sp.[Starting Date],ip.addTS,1)
                and ip.valid_to = convert(date,sp.[Ending Date])
                )
            join
                ext.Customer_Price_Group cpg
            on
                (
                    sp.[Sales Type] = 1
                and sp.[Sales Code] = cpg.code
                )
            join
                price_tool_feed.import_pricemap pm
            on
                (
                    ip.pricetype_id = pm.pricetype_id
                and ip.store_id = pm.store_id
                and cpg.id = pm.price_group_id
                )
            where
                (
                    ip.is_in_SP = 0
                )
        )
/*
update
    ip
set
    ip.is_in_SP = 1,
    ip.is_in_next_post = case when ip.external_id = y.external_id then 1 else 0 end
from 
    price_tool_feed.import_pricelist ip
outer apply
    (
        select top 1
            external_id
        from
            price_tool_feed.import_pricelist pl
        where
            (
                ip.filelist_id = pl.filelist_id
            and ip.pricetype_id = pl.pricetype_id
            and ip.item_id = pl.item_id
            and ip.zone_id = pl.zone_id
            and ip.valid_from = pl.valid_from
            and ip.valid_to = pl.valid_to
            and lower(pl.external_id) in (select [External ID] from [UK$Sales Price])
            )
    ) x
outer apply
    (
        select top 1
            external_id
        from
            price_tool_feed.import_pricelist pl
        cross apply
            (
                select
                    datefromparts(2099,12,31) valid_to
            ) eot --end of time
        where
            (
                ip.pricetype_id = pl.pricetype_id
            and ip.item_id = pl.item_id
            and ip.zone_id = pl.zone_id
            and ip.price = pl.price
            and ip.valid_from = pl.valid_from
            and isnull(ip.valid_to,eot.valid_to) = isnull(pl.valid_to,eot.valid_to)
            and lower(pl.external_id) in (select [External ID] from [UK$Sales Price])
            )
        order by
            pl.filelist_id asc
    ) y
where 
    (       
        x.external_id > 0x0
    and ip.is_in_SP = 0
    )
*/

declare @message nvarchar(max) = '', @count int

declare @t table (external_id uniqueidentifier, is_nav_error bit, issue_raised nvarchar(max), r int)

insert into @t (external_id, is_nav_error, issue_raised, r)
select
    ip.external_id,
    0,
    concat
        (
            '<li>',
            '<b>',
            i.No_,
            '</b>',
            ' ',
            z.zone_name,
            ' zone ',
            pt.price_type,
            ' price for ',
            format(ip.price, 'c', 'en-GB'),
            ' between ',
            format(ip.valid_from,'dd/MM/yyyy'),
            ' and ',
            format(ip.valid_to,'dd/MM/yyyy'),
            ' - ',
                case when 
                    ip.valid_to <= convert(date,getutcdate())
                then
                    'Date range is in the past'
                else
                    case when 
                        pt.is_rrp = 1 
                    then 
                        'Error unknown, please raise with the Business Intelligence Team'
                    when
                        ip.price > (isnull(rrp.rrp,0)-isnull(ss_discount.discount,0))
                    then                 
                        concat('Promotional price is higher than RRP (',format(isnull(rrp.rrp,0), 'c', 'en-GB'),')',case when ss_discount.discount > 0 then concat(' less subs fixed discount of ',format(ss_discount.discount, 'c', 'en-GB')) end)
                    else
                        'Error unknown, please raise with the Business Intelligence Team'
                    end
                end,
            '</li>'
         ) issue_raised,
    row_number() over (partition by ip.filelist_id, ip.pricetype_id, ip.item_id, ip.zone_id, ip.price, ip.valid_from, ip.valid_to order by ip.store_id)
from
    price_tool_feed.import_pricelist ip
join
    price_tool_feed.import_filelist fl
on
    (
        ip.filelist_id = fl.id
    )
join
    price_tool_feed.import_pricetype pt
on
    (
        ip.pricetype_id = pt.id
    )
join
    price_tool_feed.zones z
on
    (
        ip.zone_id = z.zone_id
    )
join
    ext.Item i
on
    (
        ip.item_id = i.ID
    )
cross apply
    (
        select
            _file.id
        from
            (
                select top 1
                    _if.id
                from
                    price_tool_feed.import_filelist _if
                order by
                    _if.id desc
            ) _file
        where
            (
                _file.id = ip.filelist_id
            )
    ) __file
outer apply
    (
        select 
            max(discount.discount) discount
        from
            price_tool_feed.subs_fixed_discount discount
        join
            price_tool_feed.import_pricemap map
        on
            (
                discount.price_group_id = map.price_group_id
            )
        join
            price_tool_feed.stores s
        on
            (
                map.store_id = s.store_id
            )
        where
            (
                ip.store_id = map.store_id
            and ip.pricetype_id = map.pricetype_id
            and ip.price >= discount.price
            and s.is_sub = 1
            )
    ) ss_discount
outer apply
    (
        select
            min([Unit Price]) rrp
        from
            [UK$Sales Price] sp
        where
            (
                sp.[Item No_] = i.No_
            and sp.[Sales Type] = 1
            and sp.[Sales Code] = 'FULLPRICES'
            and sp.[Starting Date] <= ip.valid_from
            and sp.[Ending Date] >= ip.valid_to
            and nullif(sp.[Currency Code],'') is null
            )
    ) rrp
where
    (
        ip.is_in_HT = 0
    and ip.external_id not in (select external_id from price_tool_feed.export_pricelist_errorlog)
    and fl.is_done = 1
    and fl.is_test = 0
    and ip.external_id_original is null
    )

insert into @t (external_id, is_nav_error, issue_raised, r)
select
    ip.external_id,
    1,
    concat
        (
            '<li>',
            '<b>',
            i.No_,
            '</b>',
            ' ',
            pt.price_type,
            ' price for ',
            format(ip.price, 'c', 'en-GB'),
            ' between ',
            format(ip.valid_from,'dd/MM/yyyy'),
            ' and ',
            format(ip.valid_to,'dd/MM/yyyy'),
            ' - ',
                case when
                    ht.[Ignored] = 1
                then
                    'Flagged as Ignored in NAV holding table'
                else
                    isnull(nullif(ht.[Error Msg],''),'Error unknown, please check with Business Systems')
                end,
            '</li>'
         ) issue_raised,
    1
from
    price_tool_feed.import_pricelist ip
join
    price_tool_feed.import_filelist fl
on
    (
        ip.filelist_id = fl.id
    )
join
    price_tool_feed.import_pricetype pt
on
    (
        ip.pricetype_id = pt.id
    )
join
    ext.Item i
on
    (
        ip.item_id = i.ID
    )
cross apply
    (
        select
            min(store_id) store_id,
            max(filelist_id) filelist_id
        from
            price_tool_feed.import_pricelist x
        where
            (
                ip.pricetype_id = x.pricetype_id
            and ip.item_id = x.item_id
            and ip.zone_id = x.zone_id
            and ip.price = x.price
            and ip.valid_from = x.valid_from
            and ip.valid_to = x.valid_to
            and ip.is_in_HT = x.is_in_HT
            and ip.is_in_SP = x.is_in_SP
            )
    ) agg_to_zone
cross apply
    (
        select top 1
            [Ignored],
            [Error Msg]
        from
            [dbo].[UK$Sales Price Holding Table] spht
        where
            (
                lower(ip.external_id) = spht.[External ID]
            and 
                (
                    spht.[Ignored] = 1
                or  spht.[Status] = 1             
                )
            )
    ) ht
where
    (
        ip.is_in_HT = 1
    and ip.is_in_SP = 0
    and ip.store_id = agg_to_zone.store_id
    and ip.filelist_id = agg_to_zone.filelist_id
    and ip.external_id not in (select external_id from price_tool_feed.export_pricelist_errorlog)
    and fl.is_done = 1
    )

select @count = isnull(sum(1),0) from @t where is_nav_error = 0 and r = 1

if @count > 0

    begin

        if @count = 1 set @message += 'The following entry from Yieldigo has not been imported into NAV:'

        if @count > 1 set @message += 'The following entries from Yieldigo have not been imported into NAV:'

        set @message += '<ul>'

        select
            @message += issue_raised
        from
            @t
        where
            (
                is_nav_error = 0
            and r = 1
            )

        set @message += '</ul><p>'

    end

select @count = isnull(sum(1),0) from @t where is_nav_error = 1 and r = 1

if @count > 0

    begin

        if @count = 1 set @message += 'The following entry from Yieldigo has been imported into NAV, but has not been processed:'

        if @count > 1 set @message += 'The following entries from Yieldigo have been imported into NAV, but have not been processed:'

        set @message += '<ul>'

        select
            @message += issue_raised
        from
            @t
        where
            (
                is_nav_error = 1
            and r = 1
            )

        set @message += '</ul><p>'

    end

exec db_sys.sp_email_notifications
    @subject = 'Yieldigo Import Issues',
    @bodyIntro = @message,
    @is_team_alert = 1,
    @tnc_id = 7

insert into price_tool_feed.export_pricelist_errorlog (external_id, issue_raised)
select
    external_id,
    issue_raised
from
    @t

select @count = isnull(sum(1),0) from price_tool_feed.vw_export_pricelist_post

if @count > 0

    begin

        if @count = 1 set @message = 'The following price from the import file has been successfully applied in NAV:'

        if @count > 1 set @message = 'The following prices from the import file have been successfully applied in NAV:'

        exec db_sys.sp_email_notifications
            @subject = 'Yieldigo Import Status Update',
            @bodyIntro = @message,
            @bodySource = 'price_tool_feed.vw_export_pricelist_post',
            @is_team_alert = 1,
            @tnc_id = 7

        update
            price_tool_feed.import_pricelist
        set
            is_in_next_post = 0
        where
            is_in_next_post = 1

    end

go