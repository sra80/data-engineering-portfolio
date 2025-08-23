create table forecast_feed.sales_trace
    (
        source int not null, --these can be found in db_sys.Lookup
        id int not null, --id in ext.Sales_Line, ext.Sales_Line_Archive, [Entry No_] in ILE
        auditLog_ID int null
    constraint PK__sales_trace primary key (source, id)
    )
go