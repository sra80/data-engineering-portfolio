CREATE TABLE [ext].[Location] (
    [location_code]     NVARCHAR (32) NOT NULL,
    [distribution_loc]  BIT           NOT NULL,
    [holding_loc]       BIT           NOT NULL,
    [distribution_type] NVARCHAR (32) NULL,
    [country]           NVARCHAR (2)  NULL,
    [addedUTC]          DATETIME2 (0) NOT NULL,
    [ID]                INT           IDENTITY (1, 1) NOT NULL,
    [transit_loc]       BIT           NOT NULL,
    [company_id]        INT           NOT NULL,
    [subscription_loc]  BIT           NOT NULL,
    [default_loc]       BIT           NOT NULL
);
GO

ALTER TABLE [ext].[Location]
    ADD CONSTRAINT [DF__Location__default_loc] DEFAULT ((0)) FOR [default_loc];
GO

ALTER TABLE [ext].[Location]
    ADD CONSTRAINT [DF__Location__holding_loc] DEFAULT ((0)) FOR [holding_loc];
GO

ALTER TABLE [ext].[Location]
    ADD CONSTRAINT [DF__Location__addedTS] DEFAULT (getutcdate()) FOR [addedUTC];
GO

ALTER TABLE [ext].[Location]
    ADD CONSTRAINT [DF__Location__subscription_loc] DEFAULT ((0)) FOR [subscription_loc];
GO

ALTER TABLE [ext].[Location]
    ADD CONSTRAINT [DF__Location__distribution_loc] DEFAULT ((0)) FOR [distribution_loc];
GO

ALTER TABLE [ext].[Location]
    ADD CONSTRAINT [DF__Location__transit_loc] DEFAULT ((0)) FOR [transit_loc];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__D01]
    ON [ext].[Location]([company_id] ASC) WHERE ([default_loc]=(1));
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__0F6]
    ON [ext].[Location]([company_id] ASC, [location_code] ASC);
GO

ALTER TABLE [ext].[Location]
    ADD CONSTRAINT [CK__Location__loc_type] CHECK ([distribution_loc]=(1) AND [holding_loc]=(0) AND [transit_loc]=(0) OR [distribution_loc]=(0) AND [holding_loc]=(1) AND [transit_loc]=(0) OR [distribution_loc]=(0) AND [holding_loc]=(0) AND [transit_loc]=(1) OR [distribution_loc]=(0) AND [holding_loc]=(0) AND [transit_loc]=(0));
GO

ALTER TABLE [ext].[Location]
    ADD CONSTRAINT [PK__Location] PRIMARY KEY CLUSTERED ([ID] ASC);
GO
