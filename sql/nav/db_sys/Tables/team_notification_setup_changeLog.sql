create table db_sys.team_notification_setup_changeLog
    (
        [ens_ID]            INT NOT NULL,
        [tnc_ID]            INT NOT NULL,
        [is_reply_on_same]  BIT NOT NULL,
        [row_version]       INT            NOT NULL,
        [is_current]        BIT            NOT NULL,
        [addedTSUTC]        DATETIME2 (1)  NOT NULL,
        [addedBy]           NVARCHAR (128) NOT NULL,
        [deletedTSUTC]      DATETIME2 (1)  NULL,
        [deletedBy]         NVARCHAR (128) NULL
    )