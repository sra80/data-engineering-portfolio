CREATE TABLE [marketing].[CSH_Moving_Extended] (
    [No_]                             NVARCHAR (20) NOT NULL,
    [Start Date]                      DATE          NOT NULL,
    [End Date]                        DATE          NULL,
    [Status]                          INT           NOT NULL,
    [Last Order]                      DATE          NOT NULL,
    [Opt In]                          BIT           NOT NULL,
    [Ecosystem]                       INT           NOT NULL,
    [Status Start Date]               DATE          NOT NULL,
    [Status End Date]                 DATE          NULL,
    [opt_source_key]                  INT           NOT NULL,
    [eco_state_change]                BIT           NOT NULL,
    [opt_state_change]                BIT           NOT NULL,
    [update_CSH_Moving_Extended_Item] BIT           NOT NULL
);
GO

ALTER TABLE [marketing].[CSH_Moving_Extended]
    ADD CONSTRAINT [DF__CSH_Moving_Extended__opt_source_key] DEFAULT ((-1)) FOR [opt_source_key];
GO

ALTER TABLE [marketing].[CSH_Moving_Extended]
    ADD CONSTRAINT [DF__CSH_Moving_Extended__update_CSH_Moving_Extended_Item] DEFAULT ((1)) FOR [update_CSH_Moving_Extended_Item];
GO

ALTER TABLE [marketing].[CSH_Moving_Extended]
    ADD CONSTRAINT [DF__CSH_Moving_Extended__opt_state_change] DEFAULT ((0)) FOR [opt_state_change];
GO

ALTER TABLE [marketing].[CSH_Moving_Extended]
    ADD CONSTRAINT [DF__CSH_Moving_Extended__eco_state_change] DEFAULT ((0)) FOR [eco_state_change];
GO

ALTER TABLE [marketing].[CSH_Moving_Extended]
    ADD CONSTRAINT [PK__CSH_Moving_Extended] PRIMARY KEY CLUSTERED ([No_] ASC, [Start Date] ASC);
GO
