





CREATE view [finance].[Accounts]

as

select
	 [No_] [Account No]
	,[Name] [Account Name]
from
	[dbo].[UK$G_L Account] 


union all


select '40505','Sales - Intercompany QCC to HSGY'


union all


select '25002','Intercompany payable - HSGY'


union all


select '25003','Intercompany payable - NL'


union all


select 'MA10000', 'Units Sold'


union all


select 'MA10001','Actual Order Count'


union all


select 'MA10002','Average Order Value'


union all


select 'MA10003','Gross Margin %'


union all


select 'MA10004','Total Direct Expenses'


union all


select 'MA10005','Gross Profit/Loss %'


union all


select 'MA10006','Total Overheads'


union all


select 'MA10007','EBITDA % of Net Sales'


union all


select 'MA10008','Total Other Income and Expenses'
GO
