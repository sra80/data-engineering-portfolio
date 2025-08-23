CREATE procedure [ext].[sp_Customer_Balance_Tracker]

as

set nocount on

update c set 
    c.balance = bal.bal 
from 
    ext.Customer c 
cross apply 
    (
        select 
            isnull(sum(d.[Amount (LCY)]),0) bal 
        from 
            [dbo].[UK$Detailed Cust_ Ledg_ Entry] d 
        join
            [UK$Cust_ Ledger Entry] e
        on
            (
                d.[Cust_ Ledger Entry No_] = e.[Entry No_]
            )
        where 
            (
                d.[Customer No_] = c.cus
            and convert(date,d.[Posting Date]) < convert(date,dateadd(day,-1,getutcdate()))
            and e.[Open] = 1
            )
    ) bal 
where 
    (
        c.balance != bal.bal
    )
GO
