create or alter procedure ext.sp_Item_Ledger_Entry

as

set nocount on

begin

    insert ext.Item_Ledger_Entry (company_id, ile_entry_no, country_id, value_entry_original)
    select
        1,
        [Entry No_],
        case when ile.[Document Type] in (0,1) then null else -1 end,
        v.value_entry_original
    from
        [dbo].[UK$Item Ledger Entry] ile
    left join
        ext.Item_Ledger_Entry e_ile
    on
        (
            e_ile.company_id = 1
        and ile.[Entry No_] = e_ile.ile_entry_no
        )
    cross apply
        (
            select top 1
                [Entry No_] value_entry_original
            from
                [dbo].[UK$Value Entry] ve
            where
                (
                    ile.[Entry No_] = ve.[Item Ledger Entry No_]
                )
            order by
                [Entry No_]
        ) v
    where
        (
            ile.[Posting Date] >= datefromparts(year(getutcdate())-2,1,1)
        and e_ile.company_id is null
        and e_ile.ile_entry_no is null
        )

    insert into ext.Item_Ledger_Entry (company_id, ile_entry_no, country_id, value_entry_original)
    select
        6,
        [Entry No_],
        case when ile.[Document Type] in (0,1) then null else -1 end,
        v.value_entry_original
    from
        [dbo].[IE$Item Ledger Entry] ile
    left join
        ext.Item_Ledger_Entry e_ile
    on
        (
            e_ile.company_id = 6
        and ile.[Entry No_] = e_ile.ile_entry_no
        )
    cross apply
        (
            select top 1
                [Entry No_] value_entry_original
            from
                [dbo].[IE$Value Entry] ve
            where
                (
                    ile.[Entry No_] = ve.[Item Ledger Entry No_]
                )
            order by
                [Entry No_]
        ) v
    where
        (
            ile.[Posting Date] >= datefromparts(year(getutcdate())-2,1,1)
        and e_ile.company_id is null
        and e_ile.ile_entry_no is null
        )

    declare @rc int = 1, @start datetime2 = getutcdate()

    while @rc > 0 and datediff(minute,@start,getutcdate()) <= 30

    begin

        update
            e
        set
            e.outcode_id = v.outcode_id,
            e.country_id = v.country_id,
            e.updateTS = getutcdate()
        from
            (select top 10000 company_id, ile_entry_no, outcode_id, country_id, updateTS from ext.Item_Ledger_Entry where company_id = 1 and country_id is null) e
        join
            [dbo].[UK$Item Ledger Entry] ile
        on
            (
                e.company_id = 1
            and e.ile_entry_no = ile.[Entry No_]
            )
        cross apply
            ext.fn_ile_country_outcode(1, ile.[External Document No_], ile.[Document Type], ile.[Entry No_]) v

        set @rc = @@rowcount

    end

    set @rc = 1

    set @start = getutcdate()

    while @rc > 0 and datediff(minute,@start,getutcdate()) <= 30

    begin

        update
            e
        set
            e.outcode_id = v.outcode_id,
            e.country_id = v.country_id,
            e.updateTS = getutcdate()
        from
            (select top 10000 company_id, ile_entry_no, outcode_id, country_id, updateTS from ext.Item_Ledger_Entry where company_id = 6 and country_id is null) e
        join
            [dbo].[IE$Item Ledger Entry] ile
        on
            (
                e.company_id = 6
            and e.ile_entry_no = ile.[Entry No_]
            )
        cross apply
            ext.fn_ile_country_outcode(6, ile.[External Document No_], ile.[Document Type], ile.[Entry No_]) v

        set @rc = @@rowcount

    end

    --recheck amazon where download occurs after ile processed
    update
        ile
    set
        ile.outcode_id = o.outcode_id,
        ile.country_id = o.country_id,
        ile.updateTS = getutcdate()
    from 
        ext.Item_Ledger_Entry ile
    join 
        ext.amazon_import_reconciliation air 
    on (
            ile.company_id = 1 
        and ile.ile_entry_no = air.ile_entry_no
        )
    cross apply
        ext.fn_ile_country_outcode(ile.company_id, null, 0, ile.ile_entry_no) o
    where 
        (
            ile.country_id = -1 
        and ile.addTS < air.addTS
        )

    --update value entry original entry no_
    update
        ile
    set
        ile.value_entry_original = v.value_entry_original,
        ile.updateTS = getutcdate()
    from
        ext.Item_Ledger_Entry ile
    join
        (
            select
            ve.company_id,
            ve.[Item Ledger Entry No_] ile_entry_no,
            min(ve.[Entry No_]) value_entry_original
        from
            hs_consolidated.[Value Entry] ve
        group by
            ve.company_id,
            ve.[Item Ledger Entry No_]
        ) v
    on
        (
            ile.company_id = v.company_id
        and ile.ile_entry_no = v.ile_entry_no
        )
    where
        (
            ile.value_entry_original is null
        )

end