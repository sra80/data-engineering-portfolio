CREATE PROCEDURE [db_sys].[sp_start_job_remote]
    @job_name NVARCHAR(128),
    @job_execution_id UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @t TABLE (job_execution_id UNIQUEIDENTIFIER);
    DECLARE @job_name_escaped NVARCHAR(256) = REPLACE(@job_name, '''', '''''');

    BEGIN TRY
        INSERT INTO @t (job_execution_id)
        EXEC (
            'DECLARE @je UNIQUEIDENTIFIER; ' +
            'EXEC jobs.sp_start_job @job_name = N''' + @job_name_escaped + ''', @job_execution_id = @je OUTPUT; ' +
            'SELECT @je'
        ) AT [elastic_job_agent];

        SELECT TOP (1) @job_execution_id = job_execution_id FROM @t;
    END TRY
    BEGIN CATCH
        -- Surface the remote error to the caller
        THROW;
    END CATCH
END
GO
