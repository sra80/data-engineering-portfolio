CREATE TABLE [marketing].[CSH_Moving_Extended_SKU] (
    [cus]                NVARCHAR (32) NOT NULL,
    [_start_date]        DATE          NOT NULL,
    [_end_date]          DATE          NULL,
    [_start_date_status] DATE          NOT NULL,
    [_end_date_status]   DATE          NULL,
    [_status]            INT           NOT NULL,
    [channel_code]       NVARCHAR (32) NOT NULL,
    [sku]                NVARCHAR (32) NOT NULL,
    [order_date]         DATE          NOT NULL,
    [first_order_cus]    DATE          NULL,
    [first_order_range]  DATE          NULL,
    [opt_in_email]       BIT           NOT NULL,
    [ecosystem]          INT           NOT NULL,
    [opt_source_key]     INT           NOT NULL,
    [eco_state_change]   BIT           NOT NULL,
    [opt_state_change]   BIT           NOT NULL,
    [first_order_sku]    DATE          NULL
);
GO

ALTER TABLE [marketing].[CSH_Moving_Extended_SKU]
    ADD CONSTRAINT [PK__CSH_Moving_Extended_SKU] PRIMARY KEY CLUSTERED ([cus] ASC, [_start_date] ASC, [channel_code] ASC, [sku] ASC);
GO

ALTER TABLE [marketing].[CSH_Moving_Extended_SKU]
    ADD CONSTRAINT [DF__CSH_Moving_Extended_SKU__opt_state_change] DEFAULT ((0)) FOR [opt_state_change];
GO

ALTER TABLE [marketing].[CSH_Moving_Extended_SKU]
    ADD CONSTRAINT [DF__CSH_Moving_Extended_SKU__opt_source_key] DEFAULT ((-1)) FOR [opt_source_key];
GO

ALTER TABLE [marketing].[CSH_Moving_Extended_SKU]
    ADD CONSTRAINT [DF__CSH_Moving_Extended_SKU__eco_state_change] DEFAULT ((0)) FOR [eco_state_change];
GO

CREATE NONCLUSTERED INDEX IX__03C
ON [marketing].[CSH_Moving_Extended_SKU] ([_end_date],[order_date])
INCLUDE ([_start_date_status],[_status],[first_order_cus],[first_order_range],[opt_in_email],[ecosystem],[opt_source_key],[eco_state_change],[opt_state_change],[first_order_sku])
GO

CREATE NONCLUSTERED INDEX IX__04F
ON [marketing].[CSH_Moving_Extended_SKU] ([_end_date],[_status],[order_date])
INCLUDE ([_start_date_status],[first_order_cus],[first_order_range],[opt_in_email],[ecosystem],[first_order_sku])
GO