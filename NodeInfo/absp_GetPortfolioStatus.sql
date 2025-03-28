if exists(select * from sysobjects where id = object_id(N'absp_GetPortfolioStatus') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetPortfolioStatus
end
 go
create procedure absp_GetPortfolioStatus @batchJobKey   int 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return the portfolio status for the given batch job key.

Returns:      Portfolio status

====================================================================================================
</pre>
</font>
##BD_END

##PD  @batchJobKey   ^^  The batchjob key for which the portfolio status is to be returned

*/
begin
	set nocount on
	
	declare @analysisRunKey int
	declare @nodeType int
	declare @nodeKey int
	declare @exposureKey int
	declare @parentType int
	declare @parentKey int
	declare @sql nvarchar(max)
	declare @status varchar(50)
	declare @tableName varchar(10)
	declare @nodeKeyName varchar(10)
	declare @keyName varchar(10)
	
	--Get AnalysisRunKey  for the batchjob
   	select @analysisRunKey = AnalysisRunKey from BatchJob where BatchJobKey=@batchJobKey  
   	
   	--Get NodeType to check nodeKey
	select @nodeType=NodeType from AnalysisRunInfo where AnalysisRunKey=@analysisRunKey   
	if @analysisRunKey  > 0
	begin
	print @nodeType
		if @nodeType = 1
		begin
			set @nodeKeyName='Aport_Key'
			set @keyName='AportKey'
			set @tableName='Aprtinfo'
		end
		else if @nodeType = 2
		begin
			set @nodeKeyName='Pport_Key'
			set @keyName='PportKey'
			set @tableName='Pprtinfo'
		end
		
		else if @nodeType = 23
		begin
			set @nodeKeyName='Rport_Key'
			set @keyName='RportKey'
			set @tableName='Rprtinfo'
		end
		else if @nodeType = 27
		begin
			set @nodeKeyName='Prog_Key'
			set @keyName='ProgramKey'
			set @tableName='Proginfo'
		end
		else if @nodeType = 30
		begin
			set @nodeKeyName='Case_Key'
			set @keyName='CaseKey'
			set @tableName='Caseinfo'
		end
		
		--Get NodeKey
		set @sql= 'select @nodeKey =' + @keyName + ' from AnalysisRunInfo where AnalysisRunKey=' + dbo.trim(cast(@analysisRunKey as varchar(20)))
		exec absp_MessageEx @sql
		execute sp_executesql @sql,N'@nodeKey  int output',@nodeKey  output
		
		--Get Status
		set @sql='select @status=Status from ' + @tableName + ' where ' + @nodeKeyName + ' = ' + dbo.trim(cast(@nodeKey as varchar(20)))
		exec absp_MessageEx @sql
		execute sp_executesql @sql,N'@status varchar(50) output',@status  output

	end
	
	if @analysisRunKey=0 or( @analysisRunKey > 0 and (@nodeType = 4 or @nodeType = 9))
	begin
		if @analysisRunKey=0
			select @exposureKey =ExposureKey from BatchJob where BatchJobKey=@batchJobKey
		else
			select @exposureKey =ExposureKey from AnalysisRunInfo where AnalysisRunKey=@analysisRunKey
		
		if @exposureKey > 0 or (@nodeType = 4 or @nodeType = 9) -- Handle Primary Account and Site Jobs
		begin
			--Get parent frpm exposuremap
			select @parentKey=ParentKey,@parentType=ParentType from ExposureMap where ExposureKey  = @exposureKey 
			
			--Get status from info tables
			if @parentType = 2
				select @status=Status from Pprtinfo where Pport_Key=@parentKey
			else if @parentType = 27
				select @status=Status from ProgInfo where Prog_Key=@parentKey
		end
		
		if (@exposureKey =0) -- Handle Data Generation standalone job
		begin
			select @nodeType=NodeType from BatchJob where  BatchJobKey=@batchJobKey 
			--Get status from info tables
			if @nodeType = 2
				select @status = Pprtinfo.Status from Pprtinfo inner join BatchJob on Pport_Key=BatchJob.PPortKey and BatchJobKey=@batchJobKey
			else if (@nodeType = 7 or @nodeType = 27)
				select @status = ProgInfo.Status from ProgInfo inner join BatchJob on Prog_Key=BatchJob.ProgramKey and BatchJobKey=@batchJobKey
		end
	end
	
	select @status
end




