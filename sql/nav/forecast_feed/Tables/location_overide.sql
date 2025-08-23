CREATE TABLE [forecast_feed].[location_overide] (
    [location_ID]         INT           NOT NULL,
    [location_ID_overide] INT           NULL,
    [addedTSUTC]          DATETIME2 (1) NULL,
    [holding_loc]         BIT           NULL,
    [distribution_loc]    BIT           NULL
);
GO

ALTER TABLE [forecast_feed].[location_overide]
    ADD CONSTRAINT [DF__location_overide__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO

ALTER TABLE [forecast_feed].[location_overide]
    ADD CONSTRAINT [PK__location_overide] PRIMARY KEY CLUSTERED ([location_ID] ASC);
GO
