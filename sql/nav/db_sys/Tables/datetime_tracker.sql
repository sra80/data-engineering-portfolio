create table db_sys.datetime_tracker
    (
        [stored_procedure] [nvarchar](64) NOT NULL,
        last_update datetime2(3) NOT NULL,
        place_holder uniqueidentifier NULL
        constraint PK__datetime_tracker primary key (stored_procedure)
    )