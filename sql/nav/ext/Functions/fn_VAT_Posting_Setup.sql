--ext.fn_VAT_Posting_Setup

create   function ext.fn_VAT_Posting_Setup
    (
        @company_id int,
        @Bus_Posting_Group nvarchar(10),
        @Prod_Posting_Group nvarchar(10)
    )

returns int

as

begin

declare @ID int

select @ID = ID from ext.VAT_Posting_Setup where (company_id = @company_id and Bus_Posting_Group = @Bus_Posting_Group and Prod_Posting_Group = @Prod_Posting_Group)

return @ID

end
GO
