create or alter view stock.Document_Type

as

select
    _key,
    _value
from
    db_sys.Lookup
where
    (
        tableName = 'Value Entry'
    and columnName = 'Document Type'
    )

union all

select
    1001,
    'Amazon Shipment'

union all

select
    1002,
    'On Order'

union all

select
    1003,
    'Ring Fenced'
GO
