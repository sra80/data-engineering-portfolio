create or alter procedure price_tool_feed.sp_export_pricelist
    (
        @item_id int,
        @test_filelist_id int = null
    )

as

set nocount on

declare @missing_def int, @test bit = 0, @current_ts datetime2(0) = getutcdate(), @vc_id int

select @vc_id = id from price_tool_feed.export_pricelist_vc where is_current = 1

if @vc_id is null set @vc_id = -1

if @test_filelist_id is not null begin set @test = 1 set @current_ts = (select addTS from price_tool_feed.import_filelist where id = @test_filelist_id) end

declare @t table (external_id uniqueidentifier, price_group_id int, l_id nvarchar(max), agg_external_id nvarchar(max), price money, valid_from date, valid_to date, is_new bit, external_id_root uniqueidentifier)

;with change_detection (price_group_id, l_id, external_id, price, _date, is_changed) as
    (
        select
            cal.price_group_id,
            yld.l_id,
            yld.external_id,
            isnull(yld.price, (select min(x) from (values (fullprice.price),(promo.price)) as x(x))) price,
            cal._date,
            case
                when 
                    (
                        price_group_id = lag(price_group_id) over (partition by cal.price_group_id order by cal._date)
                    and isnull(l_id,'') = lag(isnull(l_id,'')) over (partition by cal.price_group_id order by cal._date)
                    and isnull(yld.price, (select min(x) from (values (fullprice.price),(promo.price)) as x(x))) = lag(isnull(yld.price, (select min(x) from (values (fullprice.price),(promo.price)) as x(x)))) over (partition by cal.price_group_id order by cal._date)
                    )
            then
                0
            else
                1
            end
        from
            (
                select
                    dateadd(day,h_i.iteration,convert(date,@current_ts)) _date,
                    y_ip.price_group_id
                from
                    db_sys.iteration h_i
                cross apply
                    (
                        select 
                            y_im.price_group_id
                        from 
                            price_tool_feed.import_pricemap y_im
                        join
                            price_tool_feed.import_pricelist y_il
                        on
                            (
                                y_im.pricetype_id = y_il.pricetype_id
                            and y_im.store_id = y_il.store_id
                            )
                        join
                            price_tool_feed.import_filelist y_fi
                        on
                            (
                                y_il.filelist_id = y_fi.id
                            )
                        where
                            (
                                y_il.item_id = @item_id
                            and (
                                    (
                                        y_il.is_processed = 0
                                    and y_fi.is_done = 0
                                    )
                                or  y_il.filelist_id = @test_filelist_id
                                )
                            )
                        group by 
                            price_group_id
                    ) y_ip
                where
                    (
                        h_i.iteration > 0
                    and dateadd(day,h_i.iteration,convert(date,@current_ts)) <= datefromparts(year(@current_ts)+1,12,31)
                    )
            ) cal
        outer apply
            (
                select
                    convert(money,min(sp.[Unit Price] - isnull(ss_discount.discount,0))) price
                from
                    [dbo].[UK$Sales Price] sp
                join
                    ext.Item i
                on
                    (
                        i.company_id = 1
                    and sp.[Item No_] = i.No_
                    )
                outer apply
                    (
                        select 
                            max(discount.discount) discount
                        from
                            price_tool_feed.subs_fixed_discount discount
                        where
                            (
                                cal.price_group_id = discount.price_group_id
                            and sp.[Unit Price] >= discount.price
                            )
                    ) ss_discount
                where
                    (
                        i.ID = @item_id
                    and sp.[Sales Type] = 1
                    and sp.[Sales Code] = 'FULLPRICES'
                    and sp.[Starting Date] <= cal._date
                    and sp.[Ending Date] >= cal._date
                    and nullif(sp.[Currency Code],'') is null
                    )
            ) fullprice
        outer apply
            (
                select
                    convert(money,min(sp.[Unit Price])) price
                from
                    [dbo].[UK$Sales Price] sp
                join
                    ext.Item i
                on
                    (
                        i.company_id = 1
                    and sp.[Item No_] = i.No_
                    )
                where
                    (
                        i.ID = @item_id
                    and sp.[Sales Type] = 1
                    and sp.[Sales Code] = 'DEFAULT'
                    and sp.[Starting Date] <= cal._date
                    and sp.[Ending Date] >= cal._date
                    and nullif(sp.[Currency Code],'') is null
                    and try_convert(uniqueidentifier,sp.[External ID]) is null
                    )
            ) promo
        outer apply
            (
                select
                    min(l.price-isnull(sfd.discount,0)) price
                from
                    (
                        select
                            k.price,
                            k.pricetype_id,
                            k.store_id,
                            k.valid_from,
                            isnull(k.valid_to,datefromparts(year(@current_ts)+1,12,31)) valid_to,
                            k.item_id,
                            k.is_processed,
                            k.filelist_id
                        from
                            price_tool_feed.import_pricelist k
                        join
                            price_tool_feed.import_filelist f
                        on
                            (
                                k.filelist_id = f.id
                            )
                        where
                            (
                                f.is_done = 0
                            or  f.id = @test_filelist_id
                            )
                    ) l
                join
                    price_tool_feed.import_pricemap m
                on
                    (
                        l.pricetype_id = m.pricetype_id
                    and l.store_id = m.store_id
                    )
                outer apply
                    (   select
                            max(discount.discount) discount
                        from
                            price_tool_feed.subs_fixed_discount discount
                        where
                            (
                                discount.pricetype_id = l.pricetype_id
                            and m.price_group_id = discount.price_group_id
                            and l.price >= discount.price
                            )
                    ) sfd
                where
                    (
                        l.valid_from <= cal._date
                    and l.valid_to >= cal._date
                    and l.item_id = @item_id
                    and (
                            l.is_processed = 0
                        or  l.filelist_id = @test_filelist_id
                        )
                    and l.pricetype_id = 2
                    )
            ) yld_rrp
        outer apply
            (
                select
                    string_agg(l.id,'|') l_id,
                    string_agg(convert(nvarchar(36),l.external_id),'|') external_id,
                    min(l.price-isnull(sfd.discount,0)) price
                from
                    price_tool_feed.import_pricelist l
                join
                    price_tool_feed.import_filelist f
                on
                    (
                        l.filelist_id = f.id
                    )
                join
                    price_tool_feed.import_pricemap m
                on
                    (
                        l.pricetype_id = m.pricetype_id
                    and l.store_id = m.store_id
                    )
                outer apply
                    (   select
                            max(discount.discount) discount
                        from
                            price_tool_feed.subs_fixed_discount discount
                        where
                            (
                                discount.pricetype_id = l.pricetype_id
                            and m.price_group_id = discount.price_group_id
                            and l.price >= discount.price
                            )
                    ) sfd
                where
                    (
                        l.valid_from <= cal._date
                    and l.valid_to >= cal._date
                    and m.price_group_id = cal.price_group_id
                    and l.item_id = @item_id
                    and (
                            (
                                l.is_processed = 0
                            and f.is_done = 0
                            )
                        or  l.filelist_id = @test_filelist_id
                        )
                    and (
                            l.price-isnull(sfd.discount,0) <= fullprice.price
                        or  l.price-isnull(sfd.discount,0) <= yld_rrp.price
                        or  l.pricetype_id = 2
                        )
                    
                    )
            ) yld
    )
, group_assignment (grp, price_group_id, l_id, external_id, price, _date) as
    (
        select
            sum(is_changed) over (partition by price_group_id order by _date),
            price_group_id,
            l_id,
            external_id,
            price,
            _date
        from
            change_detection
    )

insert into @t (external_id, price_group_id, l_id, agg_external_id, price, valid_from, valid_to, is_new)
select
    coalesce(xt.external_id,xn.external_id,ep.external_id,newid()),
    ga.price_group_id,
    ga.l_id,
    ga.external_id,
    ga.price,
    ga.valid_from,
    replace(ga.valid_to,datefromparts(year(@current_ts)+1,12,31),datefromparts(2099,12,31)),
    case when coalesce(xn.external_id,ep.external_id,newid()) = ep.external_id then 0 else 1 end
from
    (
        select
            group_assignment.grp,
            group_assignment.price_group_id,
            group_assignment.l_id,
            group_assignment.external_id,
            group_assignment.price,
            min(group_assignment._date) valid_from,
            max(group_assignment._date) valid_to
        from
            group_assignment
        group by
            group_assignment.grp,
            group_assignment.price_group_id,
            group_assignment.l_id,
            group_assignment.external_id,
            group_assignment.price
    ) ga
outer apply
    (
        select top 1
            external_id
        from
            price_tool_feed.export_pricelist2 g
        where
            (
                g.item_id = @item_id
            and ga.price_group_id = g.price_group_id
            and ga.price = g.price
            and ga.valid_from = g.valid_from
            and ga.valid_to = g.valid_to
            )
        ) ep
outer apply
        (
            select top 1
                k.external_id
            from
                price_tool_feed.import_pricelist k
            join
                price_tool_feed.import_filelist f
            on
                (
                    k.filelist_id = f.id
                )
            cross apply
                string_split(ga.external_id,'|') s
            where
                k.external_id = try_convert(uniqueidentifier,s.value)
            and k.price = ga.price
            and 
                (
                    f.is_done = 0
                or  f.id = @test_filelist_id
                )
        ) xn
outer apply
        (
            select top 1
                k.external_id
            from
                price_tool_feed.import_pricelist k
            join
                price_tool_feed.import_filelist f
            on
                (
                    k.filelist_id = f.id
                )
            join
                (
                    select 
                        store_id,
                        pricetype_id,
                        price_group_id,
                        sum(1) over (partition by store_id, pricetype_id) c 
                    from
                        price_tool_feed.import_pricemap
                ) m
            on
                (
                    k.store_id = m.store_id
                and k.pricetype_id = m.pricetype_id
                and 
                    (
                        f.is_done = 0
                    or  f.id = @test_filelist_id
                    )
                and ga.price_group_id = m.price_group_id
                )
            cross apply
                string_split(ga.external_id,'|') s
            where
                k.external_id = try_convert(uniqueidentifier,s.value)
            and k.price = ga.price
            order by
                m.c
        ) xt

update
    t
set
    t.external_id_root = t.external_id,
    t.external_id = newid()
from
    (
        select
            external_id,
            external_id_root,
            row_number() over (partition by t.external_id, t.price_group_id order by t.valid_from) r
        from
            @t t
    ) t
where
    (
        t.r > 1
    )

update
    t
set
    t.is_new = u.is_new
from
    @t t
cross apply
    (
        select
            is_new is_new
        from
            @t q
        where
            (
                t.price_group_id = q.price_group_id
            and q.is_new = 1
            )
    ) u

if @test = 0

    begin /*46d9*/

        insert into price_tool_feed.export_pricelist_newid (external_id_root, external_id)
        select
            external_id_root,
            external_id
        from
            @t
        where
            (
                external_id_root > 0x0
            )

        if @vc_id > -1

            begin /*acf7*/

                insert into price_tool_feed.export_pricelist2 (vc_id, external_id, item_id, price_group_id, price, valid_from, valid_to)
                select
                    @vc_id,
                    t.external_id,
                    @item_id,
                    t.price_group_id,
                    t.price,
                    t.valid_from,
                    t.valid_to
                from
                    @t t
                left join
                    price_tool_feed.export_pricelist2 ep
                on
                    (
                        ep.vc_id = @vc_id
                    and t.external_id = ep.external_id
                    and t.price_group_id = ep.price_group_id
                    )
                where
                    (
                        t.price > 0
                    and t.is_new = 1
                    and ep.vc_id is null
                    and ep.external_id is null
                    and ep.price_group_id is null
                    )

            end /*acf7*/

        update price_tool_feed.import_pricelist set is_processed = 1, processTS = getutcdate() where item_id = @item_id and is_processed = 0

        select @missing_def = isnull(sum(1),0) from price_tool_feed.vw_import_pricemap_missing_def

        if @missing_def > 0

            begin /*b4fd*/

                if @missing_def = 1

                    exec db_sys.sp_email_notifications
                        @bodyIntro = 'The following Price Type and Store combination is missing from the definition lookup table price_tool_feed.import_pricemap:',
                        @bodySource = 'price_tool_feed.vw_import_pricemap_missing_def',
                        @bodyOutro = 'All prices with this combination will be held back from further processing until this has been resolved. See this <a href="https://CompanyX-sc9.visualstudio.com/Business%20Intelligence/_wiki/wikis/Business-Intelligence.wiki/312/price_tool_feed.import_pricemap">Wiki</a> for more information.',
                        @is_team_alert = 1,
                        @subject = 'Missing Price Definition processing data in Logic App hs-bi-datawarehouse-price_tool_feed-import',
                        @tnc_id = 6

                if @missing_def > 1

                    exec db_sys.sp_email_notifications
                        @bodyIntro = 'The following Price Type and Store combinations are missing from the definition lookup table price_tool_feed.import_pricemap:',
                        @bodySource = 'price_tool_feed.vw_import_pricemap_missing_def',
                        @bodyOutro = 'All prices with these combinations will be held back from further processing until this has been resolved. See this <a href="https://CompanyX-sc9.visualstudio.com/Business%20Intelligence/_wiki/wikis/Business-Intelligence.wiki/312/price_tool_feed.import_pricemap">Wiki</a> for more information.',
                        @is_team_alert = 1,
                        @subject = 'Missing Price Definition processing data in Logic App hs-bi-datawarehouse-price_tool_feed-import',
                        @tnc_id = 6

                insert into price_tool_feed.import_pricemap_exclude (store_id, pricetype_id)
                select distinct
                    store_id,
                    pricetype_id
                from
                    price_tool_feed.import_pricelist y_il
                where
                    (
                        not exists (select 1 from price_tool_feed.import_pricemap y_ip where y_il.pricetype_id = y_ip.pricetype_id and y_il.store_id = y_ip.store_id)
                    and not exists (select 1 from price_tool_feed.import_pricemap_exclude y_ipe where y_il.pricetype_id = y_ipe.pricetype_id and y_il.store_id = y_ipe.store_id)
                    and y_il.external_id is null
                    )

            end /*b4fd*/

            delete from 
                price_tool_feed.import_pricemap_exclude
            where
                exists (select 1 from price_tool_feed.import_pricemap y_ip where import_pricemap_exclude.pricetype_id = y_ip.pricetype_id and import_pricemap_exclude.store_id = y_ip.store_id)

    end /*46d9*/

if @test = 1

    begin /*b69d*/

        select * from @t order by price_group_id, valid_from

        select
            @vc_id [@vc_id],
            t.external_id,
            @item_id,
            t.price_group_id,
            t.price,
            t.valid_from,
            t.valid_to
        from
            @t t
        left join
            price_tool_feed.export_pricelist2 ep
        on
            (
                ep.vc_id = @vc_id
            and t.external_id = ep.external_id
            and t.price_group_id = ep.price_group_id
            )
        where
            (
                t.price > 0
            and t.is_new = 1
            -- and ep.vc_id is null
            -- and ep.external_id is null
            -- and ep.price_group_id is null
            )
        order by
            t.price_group_id, t.valid_from

    end /*b69d*/
    