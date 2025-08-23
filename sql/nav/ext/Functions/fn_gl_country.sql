CREATE function [ext].[fn_gl_country]
    (
		@company int,
        @docNo nvarchar(32),
        @sourceCode nvarchar(32),
        @description nvarchar(255)
    )

returns nvarchar(3)

as

begin

declare @country nvarchar(3)
--UK (added @company)
if patindex('SI%',@docNo) = 1 and @company = 1

	begin

	if nullif(@sourceCode,'') is not null select top 1 @country = [Ship-to Country_Region Code] from [dbo].[UK$Sales Invoice Header] where [No_] = @docNo --and [Sell-to Customer No_] = @sourceCode

	if nullif(@country,'') is null select top 1 @country = [Ship-to Country_Region Code] from [dbo].[UK$Sales Invoice Header] where [No_] = @docNo --and [Sell-to Customer No_] in (select value from string_split(@description,' '))

	end

if patindex('S-%',@docNo) = 1 and @company = 1

    begin

		if nullif(@sourceCode,'') is not null select top 1 @country = [Ship-to Country_Region Code] from [dbo].[UK$Sales Shipment Header] where [No_] = @docNo and [Sell-to Customer No_] = @sourceCode

		if nullif(@sourceCode,'') is not null select top 1 @country = [Ship-to Country_Region Code] from [dbo].[UK$Sales Cr_Memo Header] where [No_] = @docNo and [Sell-to Customer No_] = @sourceCode

		if nullif(@country,'') is null select top 1 @country = [Ship-to Country_Region Code] from [dbo].[UK$Sales Shipment Header] where [No_] = @docNo and [Sell-to Customer No_] in (select value from string_split(@description,' '))

		if nullif(@country,'') is null select top 1 @country = [Ship-to Country_Region Code] from [dbo].[UK$Sales Cr_Memo Header] where [No_] = @docNo and [Sell-to Customer No_] in (select value from string_split(@description,' '))
       
    end

if patindex('RP%',@docNo) = 1 and @company = 1 select top 1 @country = [Ship-to Country_Region Code] from [dbo].[UK$Return Receipt Header] where [No_] = @docNo

--added on 230125

if patindex('TR%',@docNo) = 1 and @company = 1 select top 1 @country = [Trsf_-to Country_Region Code] from [dbo].[UK$Transfer Receipt Header] where [No_] = @docNo

if patindex('TS%',@docNo) = 1 and @company = 1 select top 1 @country = [Trsf_-to Country_Region Code] from [dbo].[UK$Transfer Shipment Header] where [No_] = @docNo


--HSIE
if patindex('SI%',@docNo) = 1 and @company = 6

	begin

	if nullif(@sourceCode,'') is not null select top 1 @country = [Ship-to Country_Region Code] from [dbo].[IE$Sales Invoice Header] where [No_] = @docNo --and [Sell-to Customer No_] = @sourceCode

	if nullif(@country,'') is null select top 1 @country = [Ship-to Country_Region Code] from [dbo].[IE$Sales Invoice Header] where [No_] = @docNo --and [Sell-to Customer No_] in (select value from string_split(@description,' '))

	end

if patindex('S-%',@docNo) = 1 and @company = 6

    begin

		if nullif(@sourceCode,'') is not null select top 1 @country = [Ship-to Country_Region Code] from [dbo].[IE$Sales Shipment Header] where [No_] = @docNo and [Sell-to Customer No_] = @sourceCode

		if nullif(@sourceCode,'') is not null select top 1 @country = [Ship-to Country_Region Code] from [dbo].[IE$Sales Cr_Memo Header] where [No_] = @docNo and [Sell-to Customer No_] = @sourceCode

		if nullif(@country,'') is null select top 1 @country = [Ship-to Country_Region Code] from [dbo].[IE$Sales Shipment Header] where [No_] = @docNo and [Sell-to Customer No_] in (select value from string_split(@description,' '))

		if nullif(@country,'') is null select top 1 @country = [Ship-to Country_Region Code] from [dbo].[IE$Sales Cr_Memo Header] where [No_] = @docNo and [Sell-to Customer No_] in (select value from string_split(@description,' '))
       
    end

if patindex('RP%',@docNo) = 1 and @company = 6 select top 1 @country = [Ship-to Country_Region Code] from [dbo].[IE$Return Receipt Header] where [No_] = @docNo

if patindex('TR%',@docNo) = 1 and @company = 6 select top 1 @country = [Trsf_-to Country_Region Code] from [dbo].[IE$Transfer Receipt Header] where [No_] = @docNo

if patindex('TS%',@docNo) = 1 and @company = 6 select top 1 @country = [Trsf_-to Country_Region Code] from [dbo].[IE$Transfer Shipment Header] where [No_] = @docNo



--if patindex('PI%',@docNo) = 1 select top 1 @country = [Ship-to Country_Region Code] from [dbo].[UK$Purch_ Inv_ Header] where [No_] = @docNo --AJ removed PIs from the function as it shouldn't be used for jurisdiction overwrite in MAs - jurisdiction will be reported as recorded or UK if blank
if patindex('PI%',@docNo) = 1 set @country = 'ZZ' --AJ 230203 due to jurisdiction being incorrect in NAV - country is required to determine it accurately, but it's important that it's not overwritten for PIs based on the country, jurisdiction needs to stay as it on PIs and only overwriten to UK if blank

if nullif(@country,'') is null set @country = 'ZZ'

return @country

end
GO
