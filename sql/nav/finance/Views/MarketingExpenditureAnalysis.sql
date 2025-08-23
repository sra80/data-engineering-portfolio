


CREATE view [finance].[MarketingExpenditureAnalysis]

as

select [mc_sort], [ma_sort], [keyGLAccountNo], [Marketing Channel], [Marketing Analysis] from [ext].[Marketing_Expenditure_Analysis]
GO
