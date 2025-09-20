CREATE TABLE [db_sys].[Users_changeLog] (
    [ID]             INT              NOT NULL,
    [row_version]    INT              NOT NULL,
    [is_current]     BIT              NOT NULL,
    [ad_id]          NVARCHAR (64)    NOT NULL,
    [firstname]      NVARCHAR (32)    NULL,
    [surname]        NVARCHAR (32)    NULL,
    [email]          NVARCHAR (255)   NULL,
    [mitel_user_key] UNIQUEIDENTIFIER NULL,
    [mitel_team_key] UNIQUEIDENTIFIER NULL,
    [addTS]          DATETIME2 (3)    NOT NULL,
    [delTS]          DATETIME2 (3)    NULL,
    [addBy]          NVARCHAR (255)    NULL,
    [delBy]          NVARCHAR (255)    NULL
);
GO

ALTER TABLE [db_sys].[Users_changeLog]
    ADD CONSTRAINT [DF__Users_changeLog__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO