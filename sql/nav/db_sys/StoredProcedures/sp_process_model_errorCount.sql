create procedure db_sys.sp_process_model_errorCount
    (
         @placeHolder nvarchar(36)
        ,@error_count int = 0
        ,@disable bit = 0
    )

as

if @disable = 0 update db_sys.process_model set error_count = @error_count where place_holder = @placeHolder

if @disable = 1 update db_sys.process_model set disable_process = 1, error_count = @error_count where place_holder = @placeHolder
GO
