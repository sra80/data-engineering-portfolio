CREATE TABLE [ext].[Shipping_Agent_Service] (
    [ID]                     INT           IDENTITY (0, 1) NOT NULL,
    [company_id]             INT           NOT NULL,
    [shipping_agent_service] NVARCHAR (10) NOT NULL,
    [shipping_agent]         NVARCHAR (10) NOT NULL,
    [addedTSUTC]             DATETIME2 (0) NOT NULL
);
GO

ALTER TABLE [ext].[Shipping_Agent_Service]
    ADD CONSTRAINT [PK__Shipping_Agent_Service] PRIMARY KEY CLUSTERED ([ID] ASC);
GO

ALTER TABLE [ext].[Shipping_Agent_Service]
    ADD CONSTRAINT [FK__Shipping_Agent_Service__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO

ALTER TABLE [ext].[Shipping_Agent_Service]
    ADD CONSTRAINT [DF__Shipping_Agent_Service__addedTSUTC] DEFAULT (sysdatetime()) FOR [addedTSUTC];
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX__D9B]
    ON [ext].[Shipping_Agent_Service]([company_id] ASC, [shipping_agent_service] ASC, [shipping_agent] ASC);
GO
