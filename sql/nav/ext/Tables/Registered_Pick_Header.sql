CREATE TABLE [ext].[Registered_Pick_Header] (
    [Type]                 INT           NOT NULL,
    [No_]                  NVARCHAR (20) NOT NULL,
    [Pick Queue Entry No_] INT           NULL,
    [Registering Date]     DATETIME      NOT NULL,
    [Process End DateTime] DATETIME2 (1) NULL,
    [Warehouse Qty Type]   INT           NULL,
    [Box Type Code]        NVARCHAR (16) NULL,
    [Whse_ Shipment Type]  INT           NOT NULL,
    [company_id]           INT           NOT NULL
);
GO

ALTER TABLE [ext].[Registered_Pick_Header]
    ADD CONSTRAINT [PK__Registered_Pick_Header] PRIMARY KEY CLUSTERED ([company_id] ASC, [Type] ASC, [No_] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__CBC]
    ON [ext].[Registered_Pick_Header]([Process End DateTime] ASC, [Pick Queue Entry No_] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__BBB]
    ON [ext].[Registered_Pick_Header]([Registering Date] ASC);
GO

CREATE NONCLUSTERED INDEX [IX__B83]
    ON [ext].[Registered_Pick_Header]([No_] ASC);
GO




/*
## **Add trigger to Box Type table (ext.Registered\_Pick\_Header)**
*/

/*
### ext.tr\_\_ext\_\_Box\_Type (trigger)
*/

--ext.tr__ext__Box_Type (trigger)





create    trigger [ext].[tr__ext__Box_Type]



on [ext].[Registered_Pick_Header]





after insert



as



begin





insert into ext.Box_Type (company_id, box_type)



select

    i.[company_id],

    i.[Box Type Code]

from

    inserted i

left join

    ext.Box_Type n

on

    (

        i.[company_id] = n.company_id 

    and i.[Box Type Code] = n.box_type

    )

where

    (

        n.company_id is null

    and n.box_type is null

    )



end
GO

ALTER TABLE [ext].[Registered_Pick_Header]
    ADD CONSTRAINT [FK__Registered_Pick_Header__company_id] FOREIGN KEY ([company_id]) REFERENCES [db_sys].[Company] ([ID]);
GO
