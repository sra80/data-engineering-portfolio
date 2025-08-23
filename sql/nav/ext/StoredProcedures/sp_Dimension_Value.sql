create procedure ext.sp_Dimension_Value

as

insert into ext.Dimension_Value ([Dimension Code], Code) select [Dimension Code], Code from dbo.[UK$Dimension Value] d where not exists (select 1 from ext.Dimension_Value e where d.[Dimension Code] = e.[Dimension Code] and d.Code = e.Code)
GO
