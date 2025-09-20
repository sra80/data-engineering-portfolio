create procedure db_sys.sp_switch_procedures
    (
        @old nvarchar(64), @new nvarchar(64)
    )

as

update db_sys.procedure_schedule set procedureName = @new where procedureName = @old

update db_sys.process_model_partitions_procedure_pairing set procedureName = @new where procedureName = @old 


--declare @old nvarchar(64) = '[ext].[sp_Customer_Status_History]', @new nvarchar(64) = '[ext].[sp_CSH_Both]'
GO
