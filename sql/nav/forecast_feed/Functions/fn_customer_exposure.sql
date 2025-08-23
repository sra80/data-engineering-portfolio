CREATE   function [forecast_feed].[fn_customer_exposure]
    (
        @company_id int,
        @nav_code nvarchar(20)
    )

returns int

as

begin

declare @key_cus int, @type_id int

select @key_cus = hs_identity.fn_Customer(@company_id,@nav_code)

if not exists (select ID from forecast_feed.customer_exposure where is_customer = 1 and ID = @key_cus)

    begin

    select 
        @type_id = ID_grp 
    from 
        ext.Customer_Type ct
    join
        hs_consolidated.Customer h_c
    on
        (
            ct.company_id = h_c.company_id
        and ct.nav_code = isnull(nullif(h_c.[Customer Type],''),'DIRECT')
        )
    where
        (
            h_c.company_id = @company_id
        and h_c.No_ = @nav_code
        )

    if (select ID from forecast_feed.customer_exposure where is_type = 1 and is_d2c_agg = 0 and ID = @type_id and is_excluded = 0) is null set @key_cus = -@type_id-1

    if (select ID from forecast_feed.customer_exposure where is_type = 1 and is_d2c_agg = 1 and ID = @type_id and is_excluded = 0) = @type_id set @key_cus = -1000

    if (select ID from forecast_feed.customer_exposure where is_type = 1 and ID = @type_id and is_excluded = 1) = @type_id set @key_cus = -9999

    end

else

if exists (select ID from forecast_feed.customer_exposure where is_customer = 1 and ID = @key_cus and is_excluded = 1) set @key_cus = -9999

return @key_cus

end
GO
