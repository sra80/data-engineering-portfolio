create or alter procedure ext.sp_Item_Channel

as

set nocount on

declare
    @company_id int,
    @item_id int,
    @channel_id int,
    @addTS datetime2(3),
    @turn_on bit,
    @place_holder uniqueidentifier

while
    (
        select
            isnull(sum(1),0)
        from
            stg.[Item_Channel]
    ) > 0

begin

    select top 1
        @company_id = company_id,
        @item_id = (select top 1 ID from ext.Item where Item.company_id = ic.company_id and Item.No_ = ic.[Item No_]),
        @channel_id = (select top 1 ID from ext.Channel where Channel.company_id = ic.company_id and Channel.Channel_Code = ic.[Channel Code]),
        @addTS = addTS,
        @turn_on = is_insert,
        @place_holder = place_holder
    from
        stg.[Item_Channel] ic
    order by
        addTS

    if @turn_on = 0

        begin

        update 
            ext.Item_Channel
        set
            tsOff = @addTS
        where
            (
                item_id = @item_id
            and channel_id = @channel_id
            and is_current = 1
            and tsOff is null
            )

        end

    if @turn_on = 1

        begin

            update 
                ext.Item_Channel
            set
                is_current = 0
            where
                (
                    item_id = @item_id
                and channel_id = @channel_id
                and is_current = 1
                and tsOff is not null
                )

            if (select sum(1) from ext.Item_Channel where item_id = @item_id and channel_id = @channel_id and is_current = 1) is null

                begin

                insert into ext.Item_Channel
                    (
                        item_id,
                        channel_id,
                        occurrence,
                        is_current,
                        tsOn
                    )
                values
                    (
                        @item_id,
                        @channel_id,
                        isnull
                            (
                                (
                                    select
                                        max(occurrence)+1
                                    from
                                        ext.Item_Channel
                                    where
                                        (
                                            item_id = @item_id
                                        and channel_id = @channel_id
                                        )
                                )
                                    ,0
                            ),
                        1,
                        @addTS
                    )

                end


        end

    delete from stg.[Item_Channel] where place_holder = @place_holder

end