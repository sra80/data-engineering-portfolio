create or alter procedure cdc.sp_Subscriptions_Line

as

set nocount on

delete from cdc.Subscriptions_Line where [Last Modified By] in ('CompanyX\NAVPRODNASIE','CompanyX\NAVPRODSVCNAS','CompanyX\NAVPRODSVCNAS2','CompanyX\NAVPRODSVCNASQIXOL')

/* removed in favour of removal by looking at the [Last Modified By] and removing modifications by system accounts
declare @t table (cdc_instance uniqueidentifier)

declare @cdc_instance uniqueidentifier, @count_line int, @count_ndd_change int

insert into @t (cdc_instance) select distinct cdc_instance from cdc.Subscriptions_Line

while (select sum(1) from @t) > 0

    begin

        select top 1 @cdc_instance = cdc_instance from @t

        select
            @count_line = sum([@count_line]),
            @count_ndd_change = sum([@count_ndd_change])
        from
            (
                select
                    [@count_line] = (1),
                    [@count_ndd_change] = (case when isnull(dateadd(day,-[Frequency (No_ of Days)],lead([Next Delivery Date]) over (order by [Next Delivery Date])),dateadd(day,+[Frequency (No_ of Days)],lag([Next Delivery Date]) over (order by [Next Delivery Date]))) = [Next Delivery Date] then 1 else 0 end)
                from
                    cdc.Subscriptions_Line sl
                where
                    (
                        cdc_instance = @cdc_instance
                    )
            ) sq

        if @count_line = @count_ndd_change and @count_ndd_change > 0 delete from cdc.Subscriptions_Line where cdc_instance = @cdc_instance

        set @count_line = 0
        set @count_ndd_change = 0

        delete from @t where cdc_instance = @cdc_instance

    end
*/