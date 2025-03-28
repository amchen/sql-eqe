if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GenerateLocationConditionBrowserInfo') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GenerateLocationConditionBrowserInfo
end
go

create  procedure absp_GenerateLocationConditionBrowserInfo  @exposureKey int, @chunkSize int,@chunkNo int=0 , @startRowNum int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    	MSSQL
Purpose: 	The procedure will add all Location condition summary records in the 
 		LocationConditionBrowserInfo table  based on the given exposureKey.


Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

##PD  @exposureKey  ^^ The exposure key for which the browser information is to be generated.
##PD  @chunkSize  ^^ The chunk size
##PD  @exposureKey  ^^ The chunk number
##PD  @startRowNum  ^^ The start row number
*/
as
begin
 
	set nocount on;
	declare @sql varchar(max);
	declare @tmpTbl varchar(200);
	declare @tmpTbl2 varchar(200);
	declare @StepInfoViewName varchar(4000);
	declare @ConditionTypeViewName varchar(4000);
	declare @BrowserDataGenerated varchar(1);
	declare @IsOffShore int;
	declare @indexName varchar(200);
	 		
	--Return if Browser data has already been generated--
	select @BrowserDataGenerated= IsBrowserDataGenerated  from exposureinfo where ExposureKey =@exposureKey
	if @BrowserDataGenerated='Y' return

	--Check if offshore model
	select @IsOffShore=FinancialModelType from ExposureInfo where ExposureKey=@exposureKey
	
	if @chunkNo=0 set @chunkNo= @startRowNum
	
	set @tmpTbl='LocationConditionBrowserInfo_' + dbo.trim(cast(@exposureKey as varchar(50))) +'_'+ dbo.trim(cast(@chunkNo as varchar(50)))
	set @sql='if exists(select 1 from sys.tables where name=''' + @tmpTbl + ''') drop table ' + @tmpTbl
	exec (@sql)
	
	  
	--Create view for StepInfo and insert ID 0 so that lookup can be updated in a single join
	set @StepInfoViewName='VwPolStepInfo'+dbo.trim(cast(@@spId as varchar(20)))
	set @sql='if exists(select 1 from SYSOBJECTS where ID = object_id(N''' + @StepInfoViewName + ''') and objectproperty(id,N''IsView'') = 1) drop view ' + @StepInfoViewName
	exec(@sql)
	set @sql = 'create view '+ @StepInfoViewName + ' as select StepTemplateID,StepConditionName from StepInfo union select 0,'''''
	execute(@sql)

	--Create view for ConditionType and insert ID 0 so that lookup can be updated in a single join
	set @ConditionTypeViewName='VwPolConditionType'+dbo.trim(cast(@@spId as varchar(20)))
	set @sql='if exists(select 1 from SYSOBJECTS where ID = object_id(N''' + @ConditionTypeViewName + ''') and objectproperty(id,N''IsView'') = 1) drop view ' + @ConditionTypeViewName
	exec(@sql)
	set @sql = 'create view '+ @ConditionTypeViewName + ' as select ConditionTypeID,ConditionTypeName from ConditionType union select -99,'''''
	execute(@sql)
	 	
	set @tmpTbl2='TmpTbl_LocCon_' + dbo.trim(cast(@exposureKey as varchar(50))) + '_'+ dbo.trim(cast(@chunkNo as varchar(50)))
	set @sql='if exists(select 1 from sys.tables where name=''' + @tmpTbl2 + ''') drop table ' + @tmpTbl2
	exec (@sql)	
		
	--Get rows to be inserted in a temp table--
	set @sql='select distinct * into ' + @tmpTbl2 + ' from
		(
			select  A.ExposureKey,A.AccountKey,AccountNumber,SiteNumber, B.StructureKey, A.SiteKey,B.PerilID,space(35) as PerilDisplayName,B.CoverageID, 
			space(50) as CoverageDisplayName,ConditionTypeID,space(250) as ConditionTypeDisplayName,	StepTemplateID, space(50) as StepTemplateDisplayName,
			SiteCurrencyCode,StructureNumber,NULL as Value,Limit,ConditionPriority,Deductible,MinDeductible,MaxDeductible,	A.IsValid						
			from   Site A 
			left outer join SiteCondition B
			on  A.ExposureKey=B.ExposureKey and A.accountKey=B.accountKey   and A.sitekey=B.sitekey
			inner join Account C on B.ExposureKey= C.ExposureKey and B.AccountKey=C.AccountKey
			inner join Structure D on A.ExposureKey= D.ExposureKey and A.accountKey=D.accountKey  and A.SiteKey=D.siteKey
			where A.ExposureKey  = ' + cast(@exposureKey as varchar(20)) +
			' and SiteRowNum between ' + cast(@startRowNum as varchar(20)) + ' and ' + cast(@startRowNum + (@chunkSize-1) as varchar(20)) +  
			' union
			select  A.ExposureKey,A.AccountKey,AccountNumber,SiteNumber, D.StructureKey, A.SiteKey,E.PerilID,space(50) as PerilDisplayName,E.CoverageID, 
				space(50) as CoverageDisplayName,NULL as ConditionTypeID,space(50) as ConditionTypeDisplayName,NULL as StepTemplateID, space(50) as StepTemplateDisplayName,
				SiteCurrencyCode,StructureNumber,
				case when ' + cast(@IsOffShore as varchar(1)) + ' =1 and Value=1 then NULL else Value end,
				NULL as Limit,NULL as ConditionPriority,NULL as Deductible,NULL as MinDeductible,NULL as MaxDeductible,	A.IsValid			
			from   Site A 
			inner join Account C on A.ExposureKey= C.ExposureKey and A.AccountKey=C.AccountKey
			inner join Structure D on A.ExposureKey= D.ExposureKey and A.accountKey=D.accountKey  and A.SiteKey=D.siteKey
			inner join StructureCoverage E on D.ExposureKey= E.ExposureKey and D.accountKey=E.accountKey  and D.structureKey=E.structureKey and D.SiteKey=E.SiteKey
			where A.ExposureKey = '+ cast(@exposureKey as varchar(20)) + 
			' and SiteRowNum between  ' + cast(@startRowNum as varchar(20)) + ' and ' + cast(@startRowNum + (@chunkSize-1) as varchar(20)) + 
 		') as X OPTION(RECOMPILE)'
 	exec (@sql)
		
	--Do not update lookups for invalid rows--
	--Insert them in temptable
	set @sql='select  ExposureKey, AccountKey,AccountNumber,SiteNumber, StructureKey,SiteKey,cast(PerilID as varchar(35)) as PerilDisplayName,
	cast(CoverageID as varchar(50)) as CoverageDisplayName,cast(ConditionTypeID as varchar(250)) as ConditionTypeDisplayName,cast(StepTemplateID as varchar(50)) as StepTemplateDisplayName,
	SiteCurrencyCode,StructureNumber,Value,Limit,ConditionPriority,Deductible,MinDeductible,MaxDeductible,IsValid 
	into ' + @tmpTbl +
	' from ' + @tmpTbl2 + ' where IsValid=0'	
	exec (@sql)
		
	--Delete invalid rows from temp table--
	exec ('delete from ' + @tmpTbl2 + '  where IsValid=0')
	
	set @indexName=dbo.trim(@tmpTbl) +'_I1'
	set @sql='create index ' + @indexName + ' on ' + @tmpTbl + '(ExposureKey,AccountKey,StructureKey, SiteKey)'
	exec (@sql)
		
	--Insert them in LocationConditionBrowserInfo updating lookups for valid rows
	set @sql='insert into ' + @tmpTbl +
		 ' select  ExposureKey, AccountKey,AccountNumber,SiteNumber, StructureKey,SiteKey,E.PerilDisplayName as PerilDisplayName,
		 C.U_Cov_Name as CoverageDisplayName,D.ConditionTypeName as ConditionTypeDisplayName,F.StepConditionName as StepTemplateDisplayName,
		 SiteCurrencyCode,StructureNumber,Value,Limit,ConditionPriority,Deductible,MinDeductible,MaxDeductible,IsValid 
	from ' + @tmpTbl2 + '  B
	inner join Cil C on B.CoverageID =C.Cover_ID 
	inner join ' + @ConditionTypeViewName + ' D on isNull(B.ConditionTypeID,-99)=D.ConditionTypeID
	inner join Ptl E on B.PerilID=E.Peril_ID and E.Trans_Id in(66,67)
	inner join ' + @StepInfoViewName + ' F on isNull(B.StepTemplateID,0)=F.StepTemplateID' 
 	exec (@sql)
	
	set @sql='if exists(select 1 from sys.tables where name=''' + @tmpTbl2 + ''') drop table ' + @tmpTbl2
	exec (@sql)
	
	set @sql='if exists(select 1 from SYSOBJECTS where ID = object_id(N''' + @ConditionTypeViewName + ''') and objectproperty(id,N''IsView'') = 1) drop view ' + @ConditionTypeViewName
	exec(@sql)
	set @sql='if exists(select 1 from SYSOBJECTS where ID = object_id(N''' + @StepInfoViewName + ''') and objectproperty(id,N''IsView'') = 1) drop view ' + @StepInfoViewName
	exec(@sql)	
end