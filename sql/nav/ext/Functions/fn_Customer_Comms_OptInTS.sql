CREATE function [ext].[fn_Customer_Comms_OptInTS]
     (
         @cus nvarchar(32)
     )
 
 returns table
 
 as
 
 return
 select
     x.email_optin,
     x.post_optin,
     x.phone_optin,
     x.email_ts,
     x.post_ts,
     x.phone_ts
 from
     (
     select
         case when EMAIL.[Status] = 0 then 1 else 0 end email_optin,
         case when MAIL.[Status] = 0 then 1 else 0 end post_optin,
         case when TEL.[Status] = 0 then 1 else 0 end phone_optin,
         convert(datetime2(0),EMAIL.[Modified DateTime]) email_ts,
         convert(datetime2(0),MAIL.[Modified DateTime]) post_ts,
         convert(datetime2(0),TEL.[Modified DateTime]) phone_ts
     from
         (
         select
             [EMAIL],
             [MAIL],
             [TEL]
         from
             (
                 select 
                     [Entry No_],
                     [Record Code]
                 from
                     [UK$Customer Preferences Log]
                 where
                     [Customer No_] = @cus

                union

                select
                    0,
                    @cus
             ) u
         pivot
             (
                 max([Entry No_])
             for
                 [Record Code] in ([EMAIL],[MAIL],[TEL])
             ) p
         ) n
     left join
         [UK$Customer Preferences Log] EMAIL
     on
         n.EMAIL = EMAIL.[Entry No_]
     left join
         [UK$Customer Preferences Log] MAIL
     on
         n.MAIL = MAIL.[Entry No_]
     left join
         [UK$Customer Preferences Log] TEL
     on
         n.TEL = TEL.[Entry No_]
     ) x
GO
