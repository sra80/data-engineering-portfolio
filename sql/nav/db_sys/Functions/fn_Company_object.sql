--[db_sys].[fn_Company_object] (function)



CREATE     function [db_sys].[fn_Company_object]

    (

        @object_name nvarchar(128)

    )



returns nvarchar(128)



as



begin



while charindex('$',@object_name) > 0 set @object_name = right(@object_name,len(@object_name)-charindex('$',@object_name))



while charindex('[',@object_name) > 0 set @object_name = right(@object_name,len(@object_name)-charindex('[',@object_name))



while charindex(']',@object_name) > 0 set @object_name = left(@object_name,charindex(']',@object_name)-1)



return @object_name



end
GO
