
create view ext.Customer_Balance_Summary

as

with breakdown as
    (
        select
            sum(case when summary.dc = 0 then summary._count else 0 end) [debt_count],
            sum(case when summary.dc = 0 then summary._balance else 0 end) [debt_value],
            sum(case when summary.dc = 1 then summary._count else 0 end) [credit_count],
            sum(case when summary.dc = 1 then summary._balance else 0 end) [credit_value],
            summary.r
        from
            (
            select
                cat.dc,
                cat.r,
                sum(1) _count,
                sum(cat.balance) _balance
            from
                (
                select 
                    case 
                        when abs(c.balance ) < 4 then 1
                        when abs(c.balance ) < 11 then 2
                        when abs(c.balance ) < 51 then 3
                        when abs(c.balance ) < 101 then 4
                        when abs(c.balance ) < 1001 then 5
                        else 6 
                    end r,
                    case when c.balance < 0 then 1 else 0 end dc,
                    abs(c.balance) balance
                from 
                    ext.Customer c 
                where 
                    (
                        c.cus in (select No_ from dbo.[UK$Customer] d where d.[Customer Type] = 'DIRECT')
                    and abs(c.balance) > 0
                    )
                ) cat
            group by
                cat.dc,
                cat.r
            ) summary
        group by
            summary.r
    )

select
    cat [Balance Category],
    format(debt_count,'###,###,##0') [Debtors],
    format(debt_value,'£###,###,##0.00') [Debtors Value],
    format(credit_count,'###,###,##0') [Creditors],
    format(credit_value,'£###,###,##0.00') [Creditors Value],
    r
from
    (
        select
            case breakdown.r
                when 1 then '0-3'
                when 2 then '4-10'
                when 3 then '11-50'
                when 4 then '51-100'
                when 5 then '101-1000'
                when 6 then '1001+'
            end cat,
            breakdown.debt_count,
            breakdown.debt_value,
            breakdown.credit_count,
            breakdown.credit_value,
            breakdown.r
        from
            breakdown

        union all

        select
            'Total',
            sum(breakdown.debt_count),
            sum(breakdown.debt_value),
            sum(breakdown.credit_count),
            sum(breakdown.credit_value),
            7
        from
            breakdown
    ) x
GO
