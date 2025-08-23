CREATE TABLE [marketing].[CSH_Moving_Extended_Item] (
    [cus_ID]             INT  NOT NULL,
    [_start_date]        DATE NOT NULL,
    [channel_ID]         INT  NOT NULL,
    [sku_ID]             INT  NOT NULL,
    [_end_date]          DATE NULL,
    [_start_date_status] DATE NOT NULL,
    [_end_date_status]   DATE NULL,
    [sku_last_order]     DATE NULL,
    [first_order_cus]    DATE NULL,
    [first_order_range]  DATE NULL,
    [first_order_sku]    DATE NULL,
    [_status]            INT  NOT NULL,
    [opt_in_email]       BIT  NOT NULL,
    [ecosystem]          INT  NOT NULL,
    [opt_source_key]     INT  NOT NULL,
    [eco_state_change]   BIT  NOT NULL,
    [opt_state_change]   BIT  NOT NULL
);
GO

ALTER TABLE [marketing].[CSH_Moving_Extended_Item]
    ADD CONSTRAINT [DF__CSH_Moving_Extended_Item__eco_state_change] DEFAULT ((0)) FOR [eco_state_change];
GO

ALTER TABLE [marketing].[CSH_Moving_Extended_Item]
    ADD CONSTRAINT [DF__CSH_Moving_Extended_Item__opt_source_key] DEFAULT ((-1)) FOR [opt_source_key];
GO

ALTER TABLE [marketing].[CSH_Moving_Extended_Item]
    ADD CONSTRAINT [DF__CSH_Moving_Extended_Item__opt_state_change] DEFAULT ((0)) FOR [opt_state_change];
GO

ALTER TABLE [marketing].[CSH_Moving_Extended_Item]
    ADD CONSTRAINT [PK__CSH_Moving_Extended_Item] PRIMARY KEY CLUSTERED ([cus_ID] ASC, [_start_date] ASC, [channel_ID] ASC, [sku_ID] ASC);
GO
