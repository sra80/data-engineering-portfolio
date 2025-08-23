CREATE TABLE [ext].[Staff_Discount_Monitor] (
    [order_ref]       NVARCHAR (32) NOT NULL,
    [order_date]      DATE          NOT NULL,
    [discount_code]   NVARCHAR (32) NOT NULL,
    [discount_amount] MONEY         NOT NULL,
    [match_score]     INT           NOT NULL,
    [last_alert]      DATETIME2 (0) NULL
);
GO

ALTER TABLE [ext].[Staff_Discount_Monitor]
    ADD CONSTRAINT [PK__Staff_Discount_Monitor] PRIMARY KEY CLUSTERED ([order_ref] ASC);
GO
