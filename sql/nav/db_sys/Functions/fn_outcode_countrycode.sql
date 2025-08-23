create or alter function db_sys.fn_outcode_countrycode
    (
        @company_id int,
        @postcode nvarchar(16),
        @country_code nvarchar(2)
    )

returns table

as


return
    (
        with x as 
            (
                select
                    0 _order,
                    outcode_id = o.id,
                    country = o.country
                from
                    db_sys.outcode o
                where
                    (
                        charindex(' ',@postcode) > 0
                    and o.outcode = left(@postcode,charindex(' ',@postcode)-1)
                    and    
                        (
                            o.country = @country_code
                        or
                            (
                                (
                                    @country_code = 'GB'
                                or  @country_code = 'UK'
                                )
                            and o.country not in ('IE','ZZ')
                            )
                        )
                    )
            

        union all
            
                select
                    1,
                    outcode_id = o.id,
                    country = o.country
                from
                    db_sys.outcode o
                where
                    (
                        o.outcode = left(@postcode,3)
                    and o.country = 'IE'
                    and @country_code = 'IE'
                    )
            
        union all
            
                select top 1
                    2,
                    outcode_id = o.id,
                    country = o.country
                from
                    db_sys.iteration i
                join
                    db_sys.outcode o
                on
                    left(@postcode,i.iteration) = o.outcode
                where
                    (
                        i.iteration > 0
                    and i.iteration <= len(@postcode)
                    and    
                        (
                            o.country = @country_code
                        or
                            (
                                (
                                    @country_code = 'GB'
                                or  @country_code = 'UK'
                                )
                            and o.country not in ('IE','ZZ')
                            )
                        )
                    )
                order by
                    i.iteration desc
            
        union all
            
                select
                    3,
                    outcode_id = -1,
                    country = null 
             
                       
        )

        select top 1
            x.outcode_id,
            coalesce(cr0.ID,cr1.ID,-1) country_id
        from
            x
        left join
            ext.Country_Region cr0
        on
            (
                cr0.company_id = @company_id
            and x.country = cr0.country_code
            )
        left join
            ext.Country_Region cr1
        on
            (
                cr1.company_id = @company_id
            and cr1.country_code = @country_code
            )
        order by
            _order
        )