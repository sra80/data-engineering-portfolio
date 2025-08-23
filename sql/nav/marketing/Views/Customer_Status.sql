

 CREATE view [marketing].[Customer_Status]
 
 as
 
 select ID, Customer_Status, is_active, is_intro_status, is_customer from ext.Customer_Status where is_deleted = 0
GO
