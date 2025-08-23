create view ext.Payment_Refund_First_Method

as

select 
     pr.[Buying Reference No_]
    ,[Payment Method Code]
from
    [UK$Payment_Refund] pr
join
    (
        select 
            [Buying Reference No_], min(ID) ID
        from    
            [UK$Payment_Refund]
        group by
            [Buying Reference No_]
    ) first_pay_method
on
    (
        pr.[Buying Reference No_] = first_pay_method.[Buying Reference No_]
    and pr.ID = first_pay_method.ID
    )
GO
