create table db_sys.process_model_delay_register
    (
        model_name nvarchar(32) not null,
        template_message nvarchar(max) not null,
        delay_string nvarchar(32) null,
        delay_post_ts datetime2(3) null,
        queued_post_ts datetime2(3) null,
        processing_post_ts datetime2(3) null,
        back_on_track_ts datetime2(3) null,
        place_holder uniqueidentifier null
    constraint PK__process_model_delay_templates primary key (model_name)
    )
go

insert into db_sys.process_model_delay_register (model_name, template_message)
values 
    ('Finance_ChartOfAccounts','This will impact the reports in the Finance Team app in Power BI.'),
    ('Finance_SalesInvoices','This will impact the reports in the Finance app in Power BI.'),
    ('Logistics_OrderQueues','This will impact the reports in the Logistics app in Power BI.'),
    ('Logistics_StockManagement','This will impact the reports in the Stock Insight app in Power BI.'),
    ('Marketing_CRM','This will impact the reports in the Customer Insight app in Power BI.'),
    ('Marketing_CrossPlatform','This will impact the the Internation Sales report in the Marketing app in Power BI.'),
    ('Marketing_SalesOrders','This will impact the reports in the Marketing app in Power BI.')