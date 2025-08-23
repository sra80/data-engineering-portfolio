CREATE TABLE [stock].[Item_OOS] (
    [location_ID]         INT           NOT NULL,
    [item_ID]             INT           NOT NULL,
    [row_version]         INT           NOT NULL,
    [is_current]          BIT           NOT NULL,
    [addedTSUTC]          DATETIME2 (1) NOT NULL,
    [qty_on_order]        INT           NOT NULL,
    [qty_ringfence]       INT           NOT NULL,
    [qty_subs]            INT           NOT NULL,
    [qty_waiting_qa]      INT           NULL,
    [qty_open_bal]        INT           NOT NULL,
    [qty_available]       AS            (CONVERT([int],[db_sys].[fn_minus_min0](([qty_open_bal]-[qty_on_order])+[qty_ringfence]))),
    [last_sale]           DATE          NULL,
    [last_pick]           DATE          NULL,
    [est_runout]          DATE          NOT NULL,
    [ringfence_deadline]  DATE          NULL,
    [ringfence_item_card] DATE          NULL,
    [ringfence_runout]    DATE          NULL,
    [est_stock_in]        DATE          NULL,
    [est_stock_in_ref]    NVARCHAR (20) NULL,
    [est_stock_in_qty]    INT           NULL
);
GO

ALTER TABLE [stock].[Item_OOS]
    ADD CONSTRAINT [PK__Item_OOS] PRIMARY KEY CLUSTERED ([location_ID] ASC, [item_ID] ASC, [row_version] ASC);
GO
