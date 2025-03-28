if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_MergeLocationConditionBrowserInfo') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_MergeLocationConditionBrowserInfo
end
go

create  procedure absp_MergeLocationConditionBrowserInfo  @exposureKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================

DB Version:    	MSSQL

Purpose: 	The procedure will merge LocationConditionBrowserInfo records from temporary tables.


Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

##PD  @exposureKey  ^^ The exposure key for which the browser information is to be generated.


*/
as
begin
	set nocount on;

	declare @sql varchar(max);
	declare @tmpTbl varchar(200);
	declare @tName varchar(120)

	--exec absp_Util_DisableIndex 'LocationConditionBrowserInfo',1

	set @tmpTbl='LocationConditionBrowserInfo_' + dbo.trim(cast(@exposureKey as varchar(50))) +'[_]%'

	--Create Temp table to hold merged data--
	select * into #MergedData from LocationConditionBrowserInfo where 1=2
	create index #MergedData_I1 on #MergedData(ExposureKey,AccountKey,StructureKey, SiteKey)

	declare c1 cursor for select name from SYS.TABLES where name like @tmpTbl
	open c1
	fetch c1 into @tName
	while @@fetch_status=0
	begin
		set @sql='insert into #MergedData
			(ExposureKey, AccountKey,AccountNumber,SiteNumber, StructureKey,SiteKey,PerilDisplayName,CoverageDisplayName,ConditionTypeDisplayName,
			StepTemplateDisplayName,Currency,StructureNumber,Value,Limit,Priority,Deductible,MinDeductible,MaxDeductible,IsValid)
		select ExposureKey, AccountKey,AccountNumber,SiteNumber, StructureKey,SiteKey,PerilDisplayName,CoverageDisplayName,ConditionTypeDisplayName,
			StepTemplateDisplayName,SiteCurrencyCode,StructureNumber,Value,Limit,ConditionPriority,
			Case when Deductible>999999 then dbo.trim(replace(convert (varchar(50), cast(Deductible as numeric(30,2))) + '' '',''.00'','''')) else cast(Deductible as varchar(50)) end,
			Case when MinDeductible>999999 then dbo.trim(replace(convert (varchar(50), cast(MinDeductible as numeric(30,2))) + '' '',''.00'','''')) else cast(MinDeductible as varchar(50)) end,
			Case when MaxDeductible>999999 then dbo.trim(replace(convert (varchar(50), cast(MaxDeductible as numeric(30,2))) + '' '',''.00'','''')) else cast(MaxDeductible as varchar(50)) end,
			IsValid
		from ' + @tName
		exec(@sql)
		exec('drop table ' + @tName)
		fetch c1 into @tName
	end
	close c1
	deallocate c1

	insert into LocationConditionBrowserInfo
		(ExposureKey, AccountKey,AccountNumber,SiteNumber, StructureKey,SiteKey,PerilDisplayName,CoverageDisplayName,ConditionTypeDisplayName,
			StepTemplateDisplayName,Currency,StructureNumber,Value,Limit,Priority,Deductible,MinDeductible,MaxDeductible,IsValid)
		select ExposureKey, AccountKey,AccountNumber,SiteNumber, StructureKey,SiteKey,PerilDisplayName,CoverageDisplayName,ConditionTypeDisplayName,
			StepTemplateDisplayName,Currency,StructureNumber,Value,Limit,Priority,Deductible,MinDeductible,MaxDeductible,IsValid from #MergedData
			order by ExposureKey,AccountKey,StructureKey, SiteKey
	--exec absp_Util_DisableIndex 'LocationConditionBrowserInfo',0

	--Update isBrowserDataGenerated flag
	update exposureInfo set isBrowserDataGenerated='Y' where exposureKey=@exposureKey
end




