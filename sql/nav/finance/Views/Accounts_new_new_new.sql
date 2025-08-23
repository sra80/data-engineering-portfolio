create or alter view finance.Accounts_new_new_new

as

with _0 as
    (
        select
            [company_id],
            [Entry No_],
            [Parent Entry No_],
            [Presentation Order],
            [Description],
            [Indentation]
        from
            [NAV_PROD_REPL].[hs_consolidated].[G_L Account Category]
        where
            [Indentation] = 0
    )

, _1 as
    (
        select
            [company_id],
            [Entry No_],
            [Parent Entry No_],
            [Presentation Order],
            [Description],
            [Indentation]
        from
            [NAV_PROD_REPL].[hs_consolidated].[G_L Account Category]
        where
            [Indentation] = 1
    )

, _2 as
    (
        select
            [company_id],
            [Entry No_],
            [Parent Entry No_],
            [Presentation Order],
            [Description],
            [Indentation]
        from
            [NAV_PROD_REPL].[hs_consolidated].[G_L Account Category]
        where
            [Indentation] = 2
    )

, _3 as
    (
        select
            [company_id],
            [Entry No_],
            [Parent Entry No_],
            [Presentation Order],
            [Description],
            [Indentation]
        from
            [NAV_PROD_REPL].[hs_consolidated].[G_L Account Category]
        where
            [Indentation] = 3
    )

, glac as
    (
        select
            _0.company_id,
            _0.[Entry No_],
            _0.[Presentation Order],
            _0.[Description] [Account Group],
            null [Account Category],
            null [Account Subcategory],
            null [Account Subsubcategory]
        from
            _0

        union all

        select
            _1.company_id,
            _1.[Entry No_],
            _1.[Presentation Order],
            _0.[Description] [Account Group],
            _1.[Description] [Account Category],
            null [Account Subcategory],
            null [Account Subsubcategory]
        from
            _1
        join
            _0
        on
            (
                _1.company_id = _0.company_id
            and _1.[Parent Entry No_] = _0.[Entry No_]
            )

        union all

        select
            _2.company_id,
            _2.[Entry No_],
            _2.[Presentation Order],
            _0.[Description] [Account Group],
            _1.[Description] [Account Category],
            _2.[Description] [Account Subcategory],
            null [Account Subsubcategory]
        from
            _2
        join
            _1
        on
            (
                _2.company_id = _1.company_id
            and _2.[Parent Entry No_] = _1.[Entry No_]
            )
        join
            _0
        on
            (
                _1.company_id = _0.company_id
            and _1.[Parent Entry No_] = _0.[Entry No_]
            )

        union all

        select
            _3.company_id,
            _3.[Entry No_],
            _3.[Presentation Order],
            _0.[Description] [Account Group],
            _1.[Description] [Account Category],
            _2.[Description] [Account Subcategory],
            _3.[Description] [Account Subsubcategory]
        from
            _3
        join
            _2
        on
            (
                _3.company_id = _2.company_id
            and _3.[Parent Entry No_] = _2.[Entry No_]
            )
        join
            _1
        on
            (
                _2.company_id = _1.company_id
            and _2.[Parent Entry No_] = _1.[Entry No_]
            )
        join
            _0
        on
            (
                _1.company_id = _0.company_id
            and _1.[Parent Entry No_] = _0.[Entry No_]
            )
    )
, ac as
    (
        select
            gla.company_id,
            gla.[No_],
            gla.[Name],
            db_sys.fn_Lookup('G_L Account','Income_Balance',gla.[Income_Balance]) [Income_Balance],
            glac.[Account Group],
            glac.[Account Category],
            glac.[Account Subcategory],
            glac.[Account Subsubcategory]
        from
            [hs_consolidated].[G_L Account] gla
        left join
            glac
        on
            (
                gla.company_id = glac.company_id
            and gla.[Account Subcategory Entry No_] = glac.[Entry No_]
            )
        where
            (
                gla.[Account Type] = 0
            )
    )

select
    y.No_,
    y.Name,
    y.[Income_Balance],
    y.[Account Group],
    y.[Account Category],
    y.[Account Subcategory],
    y.[Account Subsubcategory]
from
    (
        select
            No_
        from
            ac
        group by
            No_
    ) x
cross apply
    (
        select top 1
            ac.No_,
            ac.Name,
            ac.[Income_Balance],
            ac.[Account Group],
            ac.[Account Category],
            ac.[Account Subcategory],
            ac.[Account Subsubcategory]
        from
            ac
        where
            (
                x.No_ = ac.No_
            )
        order by
            ac.company_id asc
    ) y
