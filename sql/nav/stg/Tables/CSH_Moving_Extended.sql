CREATE TABLE [stg].[CSH_Moving_Extended] (
    [No_]               NVARCHAR (20)  NOT NULL,
    [Start Date]        DATE           NOT NULL,
    [End Date]          DATE           NULL,
    [Status]            INT            NOT NULL,
    [Last Order]        DATE           NOT NULL,
    [Opt In]            BIT            NOT NULL,
    [Ecosystem]         INT            NOT NULL,
    [Status Start Date] DATE           NOT NULL,
    [Status End Date]   DATE           NULL,
    [opt_source]        NVARCHAR (255) NULL,
    [eco_state_change]  BIT            NULL,
    [opt_state_change]  BIT            NULL
);
GO
