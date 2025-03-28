if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_MergePolicyBrowserInfo') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_MergePolicyBrowserInfo
end
go

create  procedure absp_MergePolicyBrowserInfo  @exposureKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================

DB Version:    	MSSQL

Purpose: 	The procedure will merge PolicyBrowserInfo records from temporary tables.


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

	--exec absp_Util_DisableIndex 'PolicyBrowserInfo',1
	set @tmpTbl='PolicyBrowserInfo_' + dbo.trim(cast(@exposureKey as varchar(50))) +'[_]%'
	--Create Temp table to hold merged data--
	select * into #MergedData from PolicyBrowserInfo where 1=2;
	create index #MergedData_I1 on #MergedData(ExposureKey,AccountKey,PolicyKey);

	declare c1 cursor fast_forward for select name from SYS.TABLES where name like @tmpTbl
	open c1
	fetch c1 into @tName
	while @@fetch_status=0
	begin
		set @sql='insert into #MergedData
			(ExposureKey,AccountKey,PolicyKey,PolicyNumber, AccountNumber,PolicyName,InceptionDate,
			ExpirationDate,PolicyStatusDisplayName,LineOfBusinessDisplayName,ProRata,Currency, UnderCover, PerilDisplayName,
			CoverageDisplayName,ConditionTypeDisplayName, StepTemplateDisplayName, Limit ,
			Deductible,MinDeductible,MaxDeductible,	Priority,ConditionName,LimitAssured, DeductibleAssured ,IsValid)
		select ExposureKey,AccountKey,PolicyKey,PolicyNumber, AccountNumber,PolicyName,InceptionDate,
			ExpirationDate,PolicyStatusDisplayName,LineOfBusinessDisplayName,ProRata,CurrencyCode, UnderCover, PerilDisplayName,
			CoverageDisplayName,ConditionTypeDisplayName, StepTemplateDisplayName, Limit ,
			Case when Deductible>999999 then dbo.trim(replace(convert (varchar(50), cast(Deductible as numeric(30,2))) + '' '',''.00'','''')) else cast(Deductible as varchar(50)) end,
			Case when MinDeductible>999999 then dbo.trim(replace(convert (varchar(50), cast(MinDeductible as numeric(30,2))) + '' '',''.00'','''')) else cast(MinDeductible as varchar(50)) end,
			Case when MaxDeductible>999999 then dbo.trim(replace(convert (varchar(50), cast(MaxDeductible as numeric(30,2))) + '' '',''.00'','''')) else cast(MaxDeductible as varchar(50)) end,
			ConditionPriority,ConditionName,LimitAssured, DeductibleAssured ,IsValid
		from ' + @tName
		exec (@sql)
		exec('drop table ' + @tName)
		fetch c1 into @tName
	end
	close c1
	deallocate c1

	insert into PolicyBrowserInfo
		(ExposureKey,AccountKey,PolicyKey,PolicyNumber, AccountNumber,PolicyName,InceptionDate,
			ExpirationDate,PolicyStatusDisplayName,LineOfBusinessDisplayName,ProRata,Currency, UnderCover, PerilDisplayName,
			CoverageDisplayName,ConditionTypeDisplayName, StepTemplateDisplayName, Limit ,
			Deductible,MinDeductible,MaxDeductible,	Priority,ConditionName,LimitAssured, DeductibleAssured ,IsValid)
		select ExposureKey,AccountKey,PolicyKey,PolicyNumber, AccountNumber,PolicyName,InceptionDate,
			ExpirationDate,PolicyStatusDisplayName,LineOfBusinessDisplayName,ProRata,Currency, UnderCover, PerilDisplayName,
			CoverageDisplayName,ConditionTypeDisplayName, StepTemplateDisplayName, Limit ,
			Deductible,MinDeductible,MaxDeductible,	Priority,ConditionName,LimitAssured, DeductibleAssured ,IsValid from #MergedData
			order by ExposureKey,AccountKey,PolicyKey

	--exec absp_Util_DisableIndex 'PolicyBrowserInfo',0
end




