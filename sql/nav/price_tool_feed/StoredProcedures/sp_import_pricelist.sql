create or alter procedure price_tool_feed.sp_import_pricelist
    (
        @blob_id nvarchar(128),
        @file_content nvarchar(max),
        @logicApp_ID nvarchar(36) = null,
        @place_holder uniqueidentifier
    )

as

set nocount on

declare @t table (id int identity(0,1), ArticleId nvarchar(max), ZoneId nvarchar(max), SiteId nvarchar(max), Price nvarchar(max), ValidFrom nvarchar(max), ValidTo nvarchar(max), [Type] nvarchar(max))

declare @filelist_id int, @file_name nvarchar(64), @teams_message nvarchar(max)

select top 1 @filelist_id = id, @file_name = blob_name from price_tool_feed.import_filelist where blob_id = @blob_id and place_holder = @place_holder /*this is the session place_holder*/

set @file_content = replace(@file_content,char(13),'')

declare 
    @template_header nvarchar(max) = 'ArticleId;ZoneId;SiteId;Price;ValidFrom;ValidTo;Type',
    @is_invalid bit = 1

if @template_header = (select top 1 [value] from string_split(@file_content,char(10))) set @is_invalid = 0

if @is_invalid = 1

    begin

    update price_tool_feed.import_filelist set is_invalid = 1 where id = @filelist_id

    set @teams_message = concat('The file ',@file_name,' is not structured as expected and has therefore not been processed any further.')

    if @logicApp_ID is not null set @teams_message += concat(replicate(char(10),2),'Logic App ID: ',@logicApp_ID)

    exec db_sys.sp_email_notifications
        @bodyIntro = @teams_message,
        @is_team_alert = 1,
        @subject = 'Error in Logic App hs-bi-datawarehouse-price_tool_feed-import',
        @tnc_id = 6

    end

else if @is_invalid = 0

    begin try

        insert into @t (ArticleId, ZoneId, SiteId, Price, ValidFrom, ValidTo, [Type])
        select
            nullif(d1.[1],''),
            nullif(d1.[2],''),
            nullif(d1.[3],''),
            nullif(d1.[4],''),
            nullif(d1.[5],''),
            nullif(d1.[6],''),
            nullif(d1.[7],'')
        from
            string_split(@file_content,char(10)) d0
        cross apply
            db_sys.string_split(d0.value,';') d1

        insert into price_tool_feed.import_pricetype (price_type)
        select
            typ.[Type]
        from
            (
                select distinct
                    [Type]
                from
                    @t t
                where
                    (
                        t.id > 0
                    and try_convert(int,nullif(t.ArticleId,'')) >= 0
                    )
            ) typ
        left join
            price_tool_feed.import_pricetype y_ipt
        on
            (
                typ.[Type] = y_ipt.price_type
            )
        where
            y_ipt.price_type is null

        insert into price_tool_feed.import_pricelist (id, filelist_id, pricetype_id, item_id, zone_id, store_id, price, valid_from, valid_to)
        select
            t.id + isnull((select max(id) from price_tool_feed.import_pricelist),0),
            @filelist_id filelist_id,
            y_ipt.id pricetype_id,
            t.ArticleId item_id, 
            t.ZoneId zone_id, 
            t.SiteId store_id, 
            round(t.Price,2) price, 
            convert(date,t.ValidFrom) valid_from, 
            convert(date,t.ValidTo) valid_to
        from
            @t t
        join
            price_tool_feed.import_pricetype y_ipt
        on
            (
                t.[Type] = y_ipt.price_type
            )
        left join
            price_tool_feed.import_pricelist y_ip
        on
            (
                @filelist_id = y_ip.filelist_id
            and y_ipt.id = y_ip.pricetype_id
            and t.SiteId = y_ip.store_id
            and t.ArticleId = y_ip.item_id
            )
        where
            (
                t.id > 0
            and try_convert(date,t.ValidFrom) is not null
            and y_ipt.id is not null
            and try_convert(int,nullif(t.ArticleId,'')) >= 0
            and y_ip.filelist_id is null
            and y_ip.pricetype_id is null
            and y_ip.item_id is null
            )

        update
            ip
        set
            ip.external_id_original = f.external_id
        from
            price_tool_feed.import_pricelist ip
        cross apply
            (
                select top 1
                    e.external_id
                from
                    price_tool_feed.import_pricelist e
                where
                    (
                        ip.pricetype_id = e.pricetype_id
                    and ip.item_id = e.item_id
                    and ip.zone_id = e.zone_id
                    and ip.price = e.price
                    and ip.valid_from = e.valid_from
                    and ip.valid_to = e.valid_to
                    and e.is_in_SP = 1
                    )
                order by
                    e.id
            ) f
        where
            (
                ip.external_id_original is null
            )
            
        update
            f
        set
            f.original_entry_count = isnull(ne_count._count,0)
        from
            price_tool_feed.import_filelist f
        left join
            (
                select
                    ne.filelist_id,
                    sum(1) _count
                from
                    (
                        select distinct
                            filelist_id,
                            pricetype_id,
                            item_id,
                            zone_id,
                            price,
                            valid_from,
                            valid_to
                        from 
                            price_tool_feed.import_pricelist ip  
                        where
                            nullif(external_id_original,external_id) is null        
                    ) ne
                group by
                    ne.filelist_id
            ) ne_count
            on
                (
                    f.id = ne_count.filelist_id
                )
        where
            f.original_entry_count is null
        
    end try

    begin catch

    insert into price_tool_feed.import_errors (filelist_id, error, addTS, postTS) values (@filelist_id, error_message(), getutcdate(), getutcdate())

    set @teams_message = concat('An error has occured while attempting to import the file ',@file_name,'. The error message is <i>"',error_message(),'"</i>.')

    if @logicApp_ID is not null set @teams_message += concat(replicate(char(10),2),'Logic App ID: ',@logicApp_ID)

    exec db_sys.sp_email_notifications
        @bodyIntro = @teams_message,
        @is_team_alert = 1,
        @subject = 'Error running Logic App hs-bi-datawarehouse-price_tool_feed-import',
        @tnc_id = 6

    end catch
        
go

grant execute on price_tool_feed.sp_import_pricelist to [hs-bi-datawarehouse-price_tool_feed-import]