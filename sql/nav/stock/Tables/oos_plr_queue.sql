CREATE TABLE [stock].[oos_plr_queue] (
    [item_id] INT           NOT NULL,
    [addTS]   DATETIME2 (3) NOT NULL
);
GO

ALTER TABLE [stock].[oos_plr_queue]
    ADD CONSTRAINT [DF__oos_plr_queue__addTS] DEFAULT (sysdatetime()) FOR [addTS];
GO

ALTER TABLE [stock].[oos_plr_queue]
    ADD CONSTRAINT [PK__oos_plr_queue] PRIMARY KEY CLUSTERED ([item_id] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__DF9]
    ON [stock].[oos_plr_queue]([item_id] ASC);
GO
