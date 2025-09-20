-- Stub for Elastic Jobs sp_start_job to allow local compilation.
-- In production, execution should be routed to the Elastic Job Agent.
CREATE PROCEDURE [jobs].[sp_start_job]
    @job_name NVARCHAR(128),
    @job_execution_id UNIQUEIDENTIFIER OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    -- Local stub: generate a placeholder execution id
    SET @job_execution_id = NEWID();
END
GO
