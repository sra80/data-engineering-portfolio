CREATE TABLE [stock].[oos_plr] (
    [row_version]          INT              NOT NULL,
    [rv_sub]               INT              NOT NULL,
    [ref]                  INT              NOT NULL,
    [is_batch]             BIT              NOT NULL,
    [is_po]                BIT              NOT NULL,
    [is_to]                BIT              NOT NULL,
    [is_oos]               BIT              NOT NULL,
    [is_qa]                BIT              NOT NULL,
    [is_stop]              BIT              NOT NULL,
    [is_actual]            BIT              NOT NULL,
    [entry_id]             INT              NOT NULL,
    [item_id]              INT              NOT NULL,
    [location_id]          INT              NOT NULL,
    [ldd]                  DATE             NULL,
    [erd]                  DATE             NULL,
    [sale_first]           DATE             NULL,
    [sale_last]            DATE             NULL,
    [sale_total]           INT              NULL,
    [subs_total]           INT              NULL,
    [open_balance]         INT              NULL,
    [avail_balance]        INT              NULL,
    [ring_fenced]          INT              NULL,
    [not_rf_subs_reserve]  INT              NULL,
    [subs_overdue]         INT              NULL,
    [sub_out_6m_scope]     INT              NULL,
    [sub_b4_erd]           INT              NULL,
    [on_order]             INT              NULL,
    [estimated_lost_subs]  INT              NULL,
    [estimate_cycle]       INT              NULL,
    [estimate_daily_sales] DECIMAL (28, 10) NULL,
    [estimate_daily_sales2] DECIMAL (28, 10) NULL,
    [estimate_total_sales] INT              NULL,
    [estimate_total_sales2] INT              NULL,
    [estimate_close_bal]   INT              NULL,
    [estimate_close_bal2]   INT              NULL,
    [estimate_open_date]   DATE             NULL,
    [estimate_close_date]  DATE             NULL,
    [forecast_cycle]       INT              NULL,
    [forecast_daily_sales] DECIMAL (28, 10) NULL,
    [forecast_daily_sales2] DECIMAL (28, 10) NULL,
    [forecast_total_sales] INT              NULL,
    [forecast_total_sales2] INT              NULL,
    [forecast_close_bal]   INT              NULL,
    [forecast_close_bal2]   INT              NULL,
    [forecast_open_date]   DATE             NULL,
    [forecast_close_date]  DATE             NULL,
    [addTS]                DATETIME2 (3)    NOT NULL,
    [rf_item_card]         DATE             NULL,
    [rf_runout]            DATE             NULL,
    [rf_deadline]          DATE             NULL,
    [is_po_1]              BIT              NOT NULL,
    [is_eof]               BIT              NOT NULL,
    [is_original]          BIT              NOT NULL
);
GO

ALTER TABLE [stock].[oos_plr]
    ADD CONSTRAINT [DF__oos_plr__is_po_1] DEFAULT ((0)) FOR [is_po_1];
GO

ALTER TABLE [stock].[oos_plr]
    ADD CONSTRAINT [DF__oos_plr__is_to] DEFAULT ((0)) FOR [is_to];
GO

ALTER TABLE [stock].[oos_plr]
    ADD CONSTRAINT [DF__oos_plr__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO

ALTER TABLE [stock].[oos_plr]
    ADD CONSTRAINT [DF__oos_plr__rv_sub] DEFAULT ((0)) FOR [rv_sub];
GO

ALTER TABLE [stock].[oos_plr]
    ADD CONSTRAINT [DF__oos_plr__is_eof] DEFAULT ((0)) FOR [is_eof];
GO

ALTER TABLE [stock].[oos_plr]
    ADD CONSTRAINT [DF__oos_plr__is_qa] DEFAULT ((0)) FOR [is_qa];
GO

ALTER TABLE [stock].[oos_plr]
    ADD CONSTRAINT [DF__oos_plr__is_stop] DEFAULT ((0)) FOR [is_stop];
GO

ALTER TABLE [stock].[oos_plr]
    ADD CONSTRAINT [DF__oos_plr__is_original] DEFAULT ((0)) FOR [is_original];
GO

CREATE NONCLUSTERED INDEX [IX__4AC]
    ON [stock].[oos_plr]([is_batch] ASC, [is_po] ASC, [is_to] ASC, [is_oos] ASC, [is_qa] ASC, [is_actual] ASC)
    INCLUDE([sale_total], [open_balance]);
GO

CREATE NONCLUSTERED INDEX [IX__34D]
    ON [stock].[oos_plr]([is_batch] ASC, [is_po] ASC, [is_to] ASC, [is_oos] ASC, [is_qa] ASC, [item_id] ASC)
    INCLUDE([sale_last]);
GO

CREATE NONCLUSTERED INDEX [IX__11E]
    ON [stock].[oos_plr]([row_version] ASC, [item_id] ASC)
    INCLUDE([is_qa], [is_actual], [entry_id], [ldd], [erd], [sale_first], [sale_last], [sale_total], [subs_total], [open_balance], [avail_balance], [ring_fenced], [not_rf_subs_reserve], [on_order], [estimated_lost_subs], [estimate_cycle], [estimate_daily_sales], [estimate_total_sales], [estimate_close_bal], [estimate_open_date], [estimate_close_date], [forecast_cycle], [forecast_daily_sales], [forecast_total_sales], [forecast_close_bal], [forecast_open_date], [forecast_close_date], [addTS]);
GO

CREATE NONCLUSTERED INDEX [IX__DBA]
    ON [stock].[oos_plr]([row_version] ASC, [item_id] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__7E6]
    ON [stock].[oos_plr]([row_version] ASC, [rv_sub] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__5E1]
    ON [stock].[oos_plr]([is_batch] ASC, [is_po] ASC, [is_to] ASC, [is_oos] ASC, [is_qa] ASC, [item_id] ASC, [location_id] ASC)
    INCLUDE([sale_last]);
GO

ALTER TABLE [stock].[oos_plr]
    ADD CONSTRAINT [FK__oos_plr__row_version] FOREIGN KEY ([row_version]) REFERENCES [stock].[forecast_subscriptions_version] ([row_version]);
GO

ALTER TABLE [stock].[oos_plr]
    ADD CONSTRAINT [PK__oos_plr] PRIMARY KEY CLUSTERED ([row_version] ASC, [rv_sub] ASC, [ref] ASC, [is_batch] ASC, [is_po] ASC, [is_to] ASC, [is_oos] ASC, [location_id] ASC);
GO