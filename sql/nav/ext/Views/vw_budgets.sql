
CREATE view [ext].[vw_budgets]

as

with n as
    (
        select
            bt.is_original,
            bt.is_current, 
            convert(date,cbe.[Date]) [Date], 
            cbe.[Cost Center Code], cc.[Name] [Cost Center Name], 
            ct.[Name],
            cbe.[Amount]
        from 
            [UK$Cost Budget Entry] cbe 
        join 
            [UK$Cost Type] ct 
        on 
            (cbe.[Cost Type No_] = ct.[No_]) 
        join 
            [UK$Cost Center] cc 
        on 
            (cbe.[Cost Center Code] = cc.[Code]) 
        join 
            (
                select 
                    [Name] [budget_name], 
                    case when convert(int,right([Name],2)) = min(convert(int,right([Name],2))) over (partition by convert(int,left([Name],4))) then 1 else 0 end is_original, 
                    case when convert(int,right([Name],2)) = max(convert(int,right([Name],2))) over (partition by convert(int,left([Name],4))) then 1 else 0 end is_current 
                from 
                    [UK$Cost Budget Name] 
                where
                    (
                        try_convert(int,[Name]) > 0 
                    and [Name] in 
                            (
                                select [Budget Name] from [UK$Cost Budget Entry] group by [Budget Name] having abs(sum([Amount])) > 0
                            )
                    )
            ) bt 
        on 
            (cbe.[Budget Name] = bt.[budget_name])
    )

select
    [Date],
    [Cost Center Code],
    [Cost Center Name],
    [Gross Sales_original],
    [Gross Sales_current],
    [Refunds_original],
    [Refunds_current],
    [VAT_original],
    [VAT_current],
    [Net Sales_original],
    [Net Sales_current],
    [Vouchers_original],
    [Vouchers_current],
    [Net Sales Including Vouchers_original],
    [Net Sales Including Vouchers_current],
    [Marketing Spend_original],
    [Marketing Spend_current],
    [Revenue Generating Spend_original],
    [Revenue Generating Spend_current],
    [Non Revenue Generating Spend_original],
    [Non Revenue Generating Spend_current],
    [Orders_original],
    [Orders_current],
    [Items_original],
    [Items_current],
    [Customers_original],
    [Customers_current]
from
    (
        select
            [Date],
            [Cost Center Code],
            [Cost Center Name],
            [Name]+'_original' dimension,
            Amount
        from
            n
        where
            is_original = 1

        union all

        select
            [Date],
            [Cost Center Code],
            [Cost Center Name],
            [Name]+'_current' dimension,
            Amount
        from
            n
        where
            is_current = 1
    ) u
pivot
    (
        sum([Amount])
    for
        dimension in 
            (
                [Gross Sales_original],
                [Gross Sales_current],
                [Refunds_original],
                [Refunds_current],
                [VAT_original],
                [VAT_current],
                [Net Sales_original],
                [Net Sales_current],
                [Vouchers_original],
                [Vouchers_current],
                [Net Sales Including Vouchers_original],
                [Net Sales Including Vouchers_current],
                [Marketing Spend_original],
                [Marketing Spend_current],
                [Revenue Generating Spend_original],
                [Revenue Generating Spend_current],
                [Non Revenue Generating Spend_original],
                [Non Revenue Generating Spend_current],
                [Orders_original],
                [Orders_current],
                [Items_original],
                [Items_current],
                [Customers_original],
                [Customers_current]
            )
    ) p
GO
