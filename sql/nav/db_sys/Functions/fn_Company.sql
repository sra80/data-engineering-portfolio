--[db_sys].[fn_Company] (function)





/*

## db_sys.fn_Company (function)



Returns company_id from db_sys.Company. The function has a single argument:

- @object_name nvarchar(64)



e.g. select db_sys.fn_Company('[dbo].[UK$Sales Header Archive]') returns 1 for UK

*/



--db_sys.fn_Company (function) *done*



CREATE     function [db_sys].[fn_Company]

    (

        @object_name nvarchar(128)

    )



returns int



as



begin



declare @ID int



while charindex('$',@object_name) > 0 set @object_name = left(@object_name,charindex('$',@object_name)-1)



while charindex('[',@object_name) > 0 set @object_name = right(@object_name,len(@object_name)-charindex('[',@object_name))



while charindex(']',@object_name) > 0 set @object_name = left(@object_name,charindex(']',@object_name)-1)



select @ID = ID from db_sys.Company where NAV_DB = @object_name



return @ID



end
GO
