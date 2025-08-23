
CREATE view [marketing].[budgets] as

select
    0 refunds,
    db_sys.fn_datetime_portion([Date],getutcdate(),'week') week_portion,
    [Date],
    [Cost Center Code],
    [Cost Center Name],
    [Gross Sales_original],
    [Gross Sales_current],
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
    ext.vw_budgets

union all

select
    1 refunds,
    db_sys.fn_datetime_portion([Date],getutcdate(),'week') week_portion,
    [Date],
    [Cost Center Code],
    [Cost Center Name],
    -[Refunds_original],
    -[Refunds_current],
    null [VAT_original],
    null [VAT_current],
    null  [Net Sales_original],
    null  [Net Sales_current],
    null  [Vouchers_original],
    null  [Vouchers_current],
    null  [Net Sales Including Vouchers_original],
    null  [Net Sales Including Vouchers_current],
    null  [Marketing Spend_original],
    null  [Marketing Spend_current],
    null  [Revenue Generating Spend_original],
    null  [Revenue Generating Spend_current],
    null  [Non Revenue Generating Spend_original],
    null  [Non Revenue Generating Spend_current],
    null  [Orders_original],
    null  [Orders_current],
    null  [Items_original],
    null  [Items_current],
    null  [Customers_original],
    null  [Customers_current]
from
    ext.vw_budgets

-- union all

-- select
--     0 refunds,
--     db_sys.fn_datetime_portion([Date],getutcdate(),'week') week_portion,
--     [Date],
--     'xyz',
--     'xyz',
--     100000,
--     1000000,
--     null [VAT_original],
--     null [VAT_current],
--     null  [Net Sales_original],
--     null  [Net Sales_current],
--     null  [Vouchers_original],
--     null  [Vouchers_current],
--     null  [Net Sales Including Vouchers_original],
--     null  [Net Sales Including Vouchers_current],
--     null  [Marketing Spend_original],
--     null  [Marketing Spend_current],
--     null  [Revenue Generating Spend_original],
--     null  [Revenue Generating Spend_current],
--     null  [Non Revenue Generating Spend_original],
--     null  [Non Revenue Generating Spend_current],
--     null  [Orders_original],
--     null  [Orders_current],
--     null  [Items_original],
--     null  [Items_current],
--     null  [Customers_original],
--     null  [Customers_current]
-- from
--     ext.vw_budgets
-- where
--     [Cost Center Code] = 'D2C'
GO
