CREATE TABLE [stg].[Amazon_Stock_Movement] (
    [eventDate]       DATETIME      NULL,
    [marketplace]     NVARCHAR (3)  NULL,
    [disposition]     NVARCHAR (32) NULL,
    [fnsku]           NVARCHAR (10) NULL,
    [asin]            NVARCHAR (10) NULL,
    [sku]             NVARCHAR (40) NULL,
    [openBalance]     INT           NULL,
    [inTransit]       INT           NULL,
    [receipts]        INT           NULL,
    [shipped]         INT           NULL,
    [customerReturns] INT           NULL,
    [vendorReturns]   INT           NULL,
    [whse_In_Out]     INT           NULL,
    [found]           INT           NULL,
    [lost]            INT           NULL,
    [damaged]         INT           NULL,
    [disposed]        INT           NULL,
    [other]           INT           NULL,
    [endBalance]      INT           NULL,
    [unknown]         INT           NULL,
    [location]        NVARCHAR (3)  NULL,
    [addedUTC]        DATETIME      NOT NULL
);
GO

GRANT SELECT
    ON OBJECT::[stg].[Amazon_Stock_Movement] TO [hs-amazon-api-functions]
    AS [dbo];
GO

GRANT SELECT
    ON OBJECT::[stg].[Amazon_Stock_Movement] TO [amazon_integration]
    AS [dbo];
GO

GRANT INSERT
    ON OBJECT::[stg].[Amazon_Stock_Movement] TO [hs-amazon-api-functions]
    AS [dbo];
GO

GRANT INSERT
    ON OBJECT::[stg].[Amazon_Stock_Movement] TO [amazon_integration]
    AS [dbo];
GO

ALTER TABLE [stg].[Amazon_Stock_Movement]
    ADD CONSTRAINT [DF__Amazon_Stock_Movement__addedUTC] DEFAULT (getutcdate()) FOR [addedUTC];
GO
