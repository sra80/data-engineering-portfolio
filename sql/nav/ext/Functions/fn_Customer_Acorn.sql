
CREATE function [ext].[fn_Customer_Acorn]
    (
        @cus_code nvarchar(20)
    )

returns table

as

return

select
    format(cat.Code,'00 ') + cat._description acorn_category,
    format(typ.Code,'00 ') + typ._description acorn_description
from
    ext.Customer_Acorn cus
join
    ext.Customer_Acorn_Type typ
on
    (
        cus.acorn_type = typ.code
    )
join
    ext.Customer_Acorn_Category cat
on
    (
        typ.cat_code = cat.code
    )
where
    (
        cus.cus_code = @cus_code
    )
GO
