if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GeneratePolicyBrowserInfo') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GeneratePolicyBrowserInfo
end
go

create  procedure absp_GeneratePolicyBrowserInfo @exposureKey int, @chunkSize int,@chunkNo int=0 , @startRowNum int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    	MSSQL
Purpose: 	The procedure will add all policy summary records in the PolicyBrowserInfo 
		table  based on the given exposureKey.


Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

##PD  @exposureKey  ^^ The exposure key for which the browser information is to be generated.
##PD  @chunkSize  ^^ The chunk size
##PD  @chunkNo  ^^ The chunk number
##PD  @startRowNum  ^^ The start row number
*/
as
begin
	begin try		
		set nocount on;
		declare @sql varchar(max);
		declare @tmpTbl varchar(200);
		declare @tmpTbl2 varchar(200);
		declare @StepInfoViewName varchar(4000);
		declare @ConditionTypeViewName varchar(4000);
		declare @PolicyConditionViewName varchar(4000);
		declare @PtlViewName varchar(4000);
		declare @CilViewName varchar(4000);
		declare @BrowserDataGenerated varchar(1);
		declare @indexName varchar(200);
	 		
		--Return if Browser data has already been generated--
		select @BrowserDataGenerated= IsBrowserDataGenerated  from exposureinfo where ExposureKey =@exposureKey
		if @BrowserDataGenerated='Y' return
		
		if @chunkNo=0 set @chunkNo= @startRowNum
				
		set @tmpTbl='PolicyBrowserInfo_' + dbo.trim(cast(@exposureKey as varchar(50))) + '_'+ dbo.trim(cast(@chunkNo as varchar(50)))
		set @sql='if exists(select 1 from sys.tables where name=''' + @tmpTbl + ''') drop table ' + @tmpTbl
		exec (@sql)
		
		set @tmpTbl2='TmpTbl_' + dbo.trim(cast(@exposureKey as varchar(50))) + '_'+ dbo.trim(cast(@chunkNo as varchar(50)))
		set @sql='if exists(select 1 from sys.tables where name=''' + @tmpTbl2 + ''') drop table ' + @tmpTbl2
		exec (@sql)
	
		--Create view for StepInfo and insert ID 0 so that lookup can be updated in a single join
		set @StepInfoViewName='VwPolStepInfo'+dbo.trim(cast(@@spId as varchar(20)))
		set @sql='if exists(select 1 from SYSOBJECTS where ID = object_id(N''' + @StepInfoViewName + ''') and objectproperty(id,N''IsView'') = 1) drop view ' + @StepInfoViewName
		exec(@sql)
		set @sql = 'create view '+ @StepInfoViewName + ' as select StepTemplateID,StepConditionName from StepInfo union select 0,'''''
		execute(@sql)
		
		--Create view for PolicyConditionName and insert ID 0 so that lookup can be updated in a single join
		set @PolicyConditionViewName='VwPolicyConditionName'+dbo.trim(cast(@@spId as varchar(20)))
		set @sql='if exists(select 1 from SYSOBJECTS where ID = object_id(N''' + @PolicyConditionViewName + ''') and objectproperty(id,N''IsView'') = 1) drop view ' + @PolicyConditionViewName
		exec(@sql)
		set @sql = 'create view '+ @PolicyConditionViewName + ' as select PolicyConditionNameKey,ConditionName from PolicyConditionName union select 0,'''''
		execute(@sql)
		
		--Create view for ConditionType and insert ID 0 so that lookup can be updated in a single join
		set @ConditionTypeViewName='VwPolConditionType'+dbo.trim(cast(@@spId as varchar(20)))
		set @sql='if exists(select 1 from SYSOBJECTS where ID = object_id(N''' + @ConditionTypeViewName + ''') and objectproperty(id,N''IsView'') = 1) drop view ' + @ConditionTypeViewName
		exec(@sql)
		set @sql = 'create view '+ @ConditionTypeViewName + ' as select ConditionTypeID,ConditionTypeName from ConditionType union select -99,'''''
		execute(@sql)

		--Create view for CIL and insert ID 0 so that lookup can be updated in a single join
		set @CilViewName='VwPolCil'+dbo.trim(cast(@@spId as varchar(20)))
		set @sql='if exists(select 1 from SYSOBJECTS where ID = object_id(N''' + @CilViewName + ''') and objectproperty(id,N''IsView'') = 1) drop view ' + @CilViewName
		exec(@sql)
		set @sql = 'create view '+ @CilViewName + ' as select Cover_ID,U_Cov_Name from Cil union select -99,'''''
		execute(@sql)
		
		--Create view for PTL and insert ID 0 so that lookup can be updated in a single join
		set @PtlViewName='VwPolPtl'+dbo.trim(cast(@@spId as varchar(20)))
		set @sql='if exists(select 1 from SYSOBJECTS where ID = object_id(N''' + @PtlViewName + ''') and objectproperty(id,N''IsView'') = 1) drop view ' + @PtlViewName
		exec(@sql)
		set @sql = 'create view '+ @PtlViewName + ' as select Peril_ID,PerilDisplayName,Trans_ID from Ptl union select -99,'''',66'
		execute(@sql)


		--Get rows to be inserted in a temp table--
		set @sql='select  distinct A.ExposureKey,A.AccountKey, A.PolicyKey,PolicyNumber, D.AccountNumber,PolicyName,InceptionDate, 
				ExpirationDate,policystatusID, space(75) as PolicyStatusDisplayName,LineOfBusinessID,space(50) as LineOfBusinessDisplayName,
				ProRata,CurrencyCode, UnderCover, 
				PerilID,space(35) as PerilDisplayName,CoverageID,space(50) as CoverageDisplayName,ConditionTypeID, space(250) as ConditionTypeDisplayName,
				StepTemplateID, space(50) as StepTemplateDisplayName,Limit ,
				Deductible,MinDeductible,MaxDeductible,
				ConditionPriority,ConditionName,IsLimitAssured, IsDedAssured ,A.IsValid
			into ' + @tmpTbl2 +
			' from policy a left outer join policycondition B
			on A.ExposureKey= B.ExposureKey   and A.accountKey=B.accountKey  and A.PolicyKey=B.PolicyKey	
			left outer join '+ @PolicyConditionViewName + ' C on B.PolicyConditionNameKey=C.PolicyConditionNameKey
			inner join Account D on A.ExposureKey= D.ExposureKey and A.AccountKey=D.AccountKey
			where A.ExposureKey = ' + cast(@exposureKey as varchar(20)) +
			' and PolicyRowNum  between ' + cast(@startRowNum as varchar(20)) + ' and ' + cast(@startRowNum + @chunkSize -1 as varchar(20)) + ' OPTION(RECOMPILE)'
			
		exec (@sql)
		
		--If the PolicyCondition.ConditionType = 31 (OFFCSL) then only select the record where CoverageID = 0
		--Delete others
		set @sql='delete  from ' + @tmpTbl2 + ' where ConditionTypeID=31 and CoverageID<>0'
		exec (@sql)
		
		--Do not update lookups for invalid rows
		--Insert them in temptable
		set @sql='select  ExposureKey,AccountKey,PolicyKey,PolicyNumber, AccountNumber,PolicyName,InceptionDate, 
				ExpirationDate,cast(PolicyStatusID as varchar(75)) as PolicyStatusDisplayName,cast(LineOfBusinessID as varchar(50)) as LineOfBusinessDisplayName,
				ProRata,CurrencyCode, UnderCover, cast(PerilID as varchar(35)) as PerilDisplayName,
				cast(CoverageID as varchar(50)) as CoverageDisplayName,cast(ConditionTypeID as varchar(250)) as ConditionTypeDisplayName, 
				cast(StepTemplateID as varchar(50)) as StepTemplateDisplayName , Limit ,
				Deductible,MinDeductible,MaxDeductible,	ConditionPriority,ConditionName,
				case when IsLimitAssured = ''Y'' then ''Yes'' else ''No'' end as LimitAssured, 
			case when IsDedAssured = ''Y'' then ''Yes'' else ''No'' end as DeductibleAssured,
			IsValid
		into ' + @tmpTbl +
		' from ' + @tmpTbl2 + ' where IsValid=0'	
		exec (@sql)
			
		--Delete invalid rows from temp table--
		exec ('delete from ' + @tmpTbl2 + ' where IsValid=0')
		
		set @indexName=dbo.trim(@tmpTbl) +'_I1'
		set @sql='create index ' + @indexName + ' on ' + @tmpTbl + '(ExposureKey,AccountKey,PolicyKey)'
		exec (@sql)
			
		--Insert them updating lookups for valid rows
		set @sql='insert into ' + @tmpTbl +
		' select  ExposureKey,AccountKey,PolicyKey,PolicyNumber, AccountNumber,PolicyName,InceptionDate, 
			ExpirationDate,C.Name as PolicyStatusDisplayName,D.Name as LineOfBusinessDisplayName,ProRata,CurrencyCode, UnderCover, I.PerilDisplayName as PerilDisplayName,
			H.U_Cov_Name as CoverageDisplayName,G.ConditionTypeName as ConditionTypeDisplayName, J.StepConditionName as StepTemplateDisplayName, Limit ,
			Deductible,MinDeductible,MaxDeductible,	ConditionPriority,ConditionName,
			case when IsLimitAssured = ''Y'' then ''Yes'' else ''No'' end  as LimitAssured, 
			case when IsDedAssured = ''Y'' then ''Yes'' else ''No'' end as DeductibleAssured,
			IsValid
		from ' + @tmpTbl2 + ' B  
			inner join PolicyStatus C on B.PolicyStatusID=C.PolicyStatusID  
			inner join LineofBusiness D on B.LineofBusinessId=D.LineofBusinessId
			inner join ' + @ConditionTypeViewName + ' G on isNull(B.ConditionTypeID,-99)=G.ConditionTypeID
			inner join ' + @CilViewName + ' H on isNull(B.CoverageID,-99)=H.Cover_ID
			inner join ' + @PtlViewName + ' I on isNull(B.PerilID,-99)=i.Peril_ID and i.Trans_Id in(66,67)
			inner join ' + @StepInfoViewName + ' J on isNull(B.StepTemplateID,0)=j.StepTemplateID'
		exec (@sql)	
	
 
	end try
	
	begin catch
		declare @ProcName varchar(100);
		select @ProcName=object_name(@@procid);
		exec absp_Util_GetErrorInfo @ProcName;
	end catch
	set @sql='if exists(select 1 from sys.tables where name=''' + @tmpTbl2 + ''') drop table ' + @tmpTbl2
	exec (@sql)
	
	set @sql='if exists(select 1 from SYSOBJECTS where ID = object_id(N''' + @PolicyConditionViewName + ''') and objectproperty(id,N''IsView'') = 1) drop view ' + @PolicyConditionViewName
	exec(@sql)
	set @sql='if exists(select 1 from SYSOBJECTS where ID = object_id(N''' + @ConditionTypeViewName + ''') and objectproperty(id,N''IsView'') = 1) drop view ' + @ConditionTypeViewName
	exec(@sql)
	set @sql='if exists(select 1 from SYSOBJECTS where ID = object_id(N''' + @CilViewName + ''') and objectproperty(id,N''IsView'') = 1) drop view ' + @CilViewName
	exec(@sql)
	set @sql='if exists(select 1 from SYSOBJECTS where ID = object_id(N''' + @PtlViewName + ''') and objectproperty(id,N''IsView'') = 1) drop view ' + @PtlViewName
	exec(@sql)
	set @sql='if exists(select 1 from SYSOBJECTS where ID = object_id(N''' + @StepInfoViewName + ''') and objectproperty(id,N''IsView'') = 1) drop view ' + @StepInfoViewName
	exec(@sql)
end 	 
