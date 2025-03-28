if exists(select * from sysobjects where id = object_id(N'absp_GetPortfolioStatusForAllBatchJobs') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetPortfolioStatusForAllBatchJobs
end
go

create procedure absp_GetPortfolioStatusForAllBatchJobs
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

	declare @batchJobKey   int;
	declare @dbName varchar (120);
	declare @analysisRunKey int;
	declare @nodeType int;
	declare @nodeKey int;
	declare @exposureKey int;
	declare @accountKey int;
	declare @parentType int;
	declare @parentKey int;
	declare @sql nvarchar(max);
	declare @status varchar(50);
	declare @tableName varchar(10);
	declare @nodeKeyName varchar(10);
	declare @keyName varchar(10);
	declare @demandSurge varchar(10);
	declare @frequency varchar(10);
	declare @eventType varchar(254);
	declare @nodeDispName varchar(1000);
	declare @jobType int;

	if not exists ( select  * from tempdb.dbo.sysobjects o  where o.xtype in ('U')
							and o.id = object_id(N'tempdb..#BatchJobsToBeDisplayed'))
	begin
		--print ' This procedure must be called from absp_GetBatchJobsForJobManagerDisplay';
		return;
	end

	create table #PortfolioStatus (
		BatchJobKey int,
		DemandSurge varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
		Frequency varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
		EventType varchar(254) COLLATE SQL_Latin1_General_CP1_CI_AS,
		NodeDisplayName varchar(1000) COLLATE SQL_Latin1_General_CP1_CI_AS,
		Status varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS
	);

	declare cursBatchJob  cursor fast_forward  for select distinct BatchJobKey, DatabaseName from #BatchJobsToBeDisplayed;

   	set @demandSurge = '';
   	set @frequency = '';
   	set @eventType = '';

   	open cursBatchJob
   	fetch next from cursBatchJob into @batchJobKey, @dbName

   	while @@fetch_status = 0
   	begin
   	    	set @dbName = '[' + @dbName + ']';
		set @nodeDispName = '';
		set @status = '';

		--Get AnalysisRunKey  for the batchjob
		set @sql = 'select @analysisRunKey = AnalysisRunKey, @nodeType = NodeType, @jobType = JobTypeId, @accountKey = AccountKey from commondb..BatchJob where BatchJobKey= ' + dbo.trim(cast(@batchJobKey as varchar(20)));
		execute sp_executesql @sql,N'@analysisRunKey int output, @nodeType int output, @jobType int output, @accountKey int output',@analysisRunKey  output, @nodeType  output, @jobType output, @accountKey output;
		if @nodeType = 12
		begin
			set @nodeKeyName='Folder_Key';
			set @keyName='FolderKey';
			set @tableName='FldrInfo';
		end
		else if @nodeType = 1
		begin
			set @nodeKeyName='Aport_Key';
			set @keyName='AportKey';
			set @tableName='Aprtinfo';
		end
		else if @nodeType = 2
		begin
			set @nodeKeyName='Pport_Key';
			set @keyName='PportKey';
			set @tableName='Pprtinfo';
		end

		else if @nodeType = 23
		begin
			set @nodeKeyName='Rport_Key';
			set @keyName='RportKey';
			set @tableName='Rprtinfo';
		end
		else if @nodeType = 27
		begin
			set @nodeKeyName='Prog_Key';
			set @keyName='ProgramKey';
			set @tableName='Proginfo';
		end
		else if @nodeType = 30
		begin
			set @nodeKeyName='Case_Key';
			set @keyName='CaseKey';
			set @tableName='Caseinfo';
		end
		else if @nodeType = 103 or @nodeType = 101
		begin
			set @nodeKeyName='RdbInfoKey';
			set @keyName='RdbInfoKey';
			set @tableName='RdbInfo';
		end

		-- Get the node key from BatchJob since for Import and Geocode there is no AnalysisRunInfo entries
		set @sql= 'select @nodeKey = ' + @keyName + ' from commondb..BatchJob where BatchJobKey = ' + dbo.trim(cast(@batchJobKey as varchar(20)));
		-- exec absp_MessageEx @sql;
		execute sp_executesql @sql,N'@nodeKey int output',@nodeKey  output;

		-- Get the node display name for nodes having jobs on the queue
		exec absp_getNodeDisplayName @nodeDispName out, @dbName, @batchJobKey
		if (@nodeType = 103 or @nodeType = 101)
		begin
			insert into #PortfolioStatus values (@batchJobKey, '', '', '', @nodeDispName, 'Active');
		end

		if @analysisRunKey  > 0 and (@nodeType <> 4 and @nodeType <> 9)
		begin

			--Get DemandSurge, Frequency and EventType from AvailableReports table based on the analysis run key
			set @sql = 'select @demandSurge = demandSurge, @frequency = frequency, @eventType = eventType from ' + @dbName + '..AvailableReport where AnalysisRunKey= ' + dbo.trim(cast(@analysisRunKey as varchar(20)));
			--print @sql;
			execute sp_executesql @sql,N'@demandSurge varchar(10) output , @frequency varchar(10) output, @eventType varchar(254) output',@demandSurge  output, @frequency  output, @eventType  output

			--Get NodeKey
			set @sql= 'select @nodeKey = ' + @keyName + ' from ' + @dbName + '..AnalysisRunInfo where AnalysisRunKey=' + dbo.trim(cast(@analysisRunKey as varchar(20)));
			-- exec absp_MessageEx @sql;
			execute sp_executesql @sql,N'@nodeKey int output',@nodeKey  output;

			--Get Status
			set @sql='select @status=Status from ' + @dbName + '..' + @tableName + ' where ' + @nodeKeyName + ' = ' + dbo.trim(cast(@nodeKey as varchar(20)));
			-- exec absp_MessageEx @sql;
			execute sp_executesql @sql,N'@status varchar(50) output',@status  output;
			insert into #PortfolioStatus values (@batchJobKey, @demandSurge, @frequency, @eventType, @nodeDispName, @status);
		end

		if @analysisRunKey=0 or( @analysisRunKey > 0 and (@nodeType = 4 or @nodeType = 9))
		begin
			if @analysisRunKey=0
				select @exposureKey =ExposureKey from commondb..BatchJob where BatchJobKey=@batchJobKey
			else
				begin
					set @sql = 'select @exposureKey =ExposureKey from  ' + @dbName + '..AnalysisRunInfo where AnalysisRunKey= ' + dbo.trim(cast(@analysisRunKey as varchar(20)));
					execute sp_executesql @sql,N'@exposureKey int output',@exposureKey  output;
				end

			if @exposureKey > 0 and (@nodeType = 4 or @nodeType = 9) -- Handle Primary Account and Site Jobs
			begin
				--Get parent from exposuremap
				set @sql = 'select @parentKey=ParentKey,@parentType=ParentType from ' + @dbName + '..ExposureMap where ExposureKey  = ' + dbo.trim(cast(@exposureKey as varchar(20)));
				execute sp_executesql @sql,N'@parentKey int output, @parentType int output',@parentKey output , @parentType output;

				--Get status from info tables
				if @parentType = 2
					begin
						set @sql = 'select @status=Status from ' + @dbName + '..Pprtinfo where Pport_Key=' + dbo.trim(cast(@parentKey as varchar(20)));
						execute sp_executesql @sql,N'@status varchar(50) output',@status  output;

						insert into #PortfolioStatus values (@batchJobKey, @demandSurge, @frequency, @eventType, @nodeDispName, @status);
					end
				else if @parentType = 27
					begin
						set @sql = 'select @status=Status from ' + @dbName + '..ProgInfo where Prog_Key=' + dbo.trim(cast(@parentKey as varchar(20)));
						execute sp_executesql @sql,N'@status varchar(50) output',@status  output;

						insert into #PortfolioStatus values (@batchJobKey, @demandSurge, @frequency, @eventType, @nodeDispName, @status);
					end
			end

			if @exposureKey > 0 and (@nodeType <> 4 and @nodeType <> 9)
			begin
				select @nodeType=NodeType from commondb..BatchJob where  BatchJobKey=@batchJobKey
				if @nodeType = 2
					begin
						set @sql = 'select @nodeDispName = longname, @status = ' + @dbName + '..Pprtinfo.Status from ' + @dbName + '..Pprtinfo inner join commondb..BatchJob BatchJob on Pport_Key=BatchJob.PPortKey and BatchJobKey= ' + dbo.trim(cast(@batchJobKey as varchar(20)));
						execute sp_executesql @sql,N'@nodeDispName varchar(1000) output, @status varchar(50) output', @nodeDispName  output, @status  output;
						insert into #PortfolioStatus values (@batchJobKey, @demandSurge, @frequency, @eventType, @nodeDispName, @status);
					end
				else if (@nodeType = 7 or @nodeType = 27)
					begin
						set @sql = 'select @nodeDispName = longname, @status = ' + @dbName + '..ProgInfo.Status from ' + @dbName + '..ProgInfo inner join commondb..BatchJob BatchJob on Prog_Key=BatchJob.ProgramKey and BatchJobKey= ' + dbo.trim(cast(@batchJobKey as varchar(20)));
						execute sp_executesql @sql,N'@nodeDispName varchar(1000) output, @status varchar(50) output', @nodeDispName  output, @status  output;
						insert into #PortfolioStatus values (@batchJobKey, @demandSurge, @frequency, @eventType, @nodeDispName, @status);
					end
			end


			if (@exposureKey=0 and @jobType in (24, 28, 50)) -- Handle Data Generation standalone job
			begin
				select @nodeType=NodeType from commondb..BatchJob where  BatchJobKey=@batchJobKey
				--Get status from info tables
				if @nodeType = 2
					begin
						set @sql = 'select @nodeDispName = longname, @status = ' + @dbName + '..Pprtinfo.Status from ' + @dbName + '..Pprtinfo inner join commondb..BatchJob BatchJob on Pport_Key=BatchJob.PPortKey and BatchJobKey= ' + dbo.trim(cast(@batchJobKey as varchar(20)));
						execute sp_executesql @sql,N'@nodeDispName varchar(1000) output, @status varchar(50) output', @nodeDispName  output, @status  output;
						insert into #PortfolioStatus values (@batchJobKey, @demandSurge, @frequency, @eventType, @nodeDispName, @status);
					end
				else if @nodeType = 23
					begin
						set @sql = 'select @nodeDispName = longname, @status = ' + @dbName + '..Rprtinfo.Status from ' + @dbName + '..Rprtinfo inner join commondb..BatchJob BatchJob on Rport_Key=BatchJob.RPortKey and BatchJobKey= ' + dbo.trim(cast(@batchJobKey as varchar(20)));
						execute sp_executesql @sql,N'@nodeDispName varchar(1000) output, @status varchar(50) output', @nodeDispName  output, @status  output;
						insert into #PortfolioStatus values (@batchJobKey, @demandSurge, @frequency, @eventType, @nodeDispName, @status);
					end
				else if @nodeType = 30
					begin
						set @sql = 'select @nodeDispName = longname, @status = ' + @dbName + '..CaseInfo.Status from ' + @dbName + '..CaseInfo inner join commondb..BatchJob BatchJob on CaseKey=BatchJob.CaseKey and BatchJobKey= ' + dbo.trim(cast(@batchJobKey as varchar(20)));
						execute sp_executesql @sql,N'@nodeDispName varchar(1000) output, @status varchar(50) output', @nodeDispName  output, @status  output;
						insert into #PortfolioStatus values (@batchJobKey, @demandSurge, @frequency, @eventType, @nodeDispName, @status);
					end	
				else if @nodeType = 1
					begin
						set @sql = 'select @nodeDispName = longname, @status = ' + @dbName + '..Aprtinfo.Status from ' + @dbName + '..Aprtinfo inner join commondb..BatchJob BatchJob on Aport_Key=BatchJob.APortKey and BatchJobKey= ' + dbo.trim(cast(@batchJobKey as varchar(20)));
						execute sp_executesql @sql,N'@nodeDispName varchar(1000) output, @status varchar(50) output', @nodeDispName  output, @status  output;
						insert into #PortfolioStatus values (@batchJobKey, @demandSurge, @frequency, @eventType, @nodeDispName, @status);
					end	
				else if (@nodeType = 7 or @nodeType = 27)
					begin
						set @sql = 'select @status = ' + @dbName + '..ProgInfo.Status from ' + @dbName + '..ProgInfo inner join commondb..BatchJob BatchJob on Prog_Key=BatchJob.ProgramKey and BatchJobKey= ' + dbo.trim(cast(@batchJobKey as varchar(20)));
						execute sp_executesql @sql,N'@status varchar(50) output',@status  output;

						set @sql= 'select @nodeDispName =  c.longname + '':'' + a.longname from ' + @dbName + '..' + 'proginfo a inner join ' + @dbName + '..' + 'rportmap b on b.child_key = a.prog_key inner join ' + @dbName + '..' + 'rprtinfo c on c.rport_key = b.rport_key  inner join commondb..BatchJob BatchJob on Prog_Key=BatchJob.ProgramKey and BatchJobKey= ' + dbo.trim(cast(@batchJobKey as varchar(20)));
						-- exec absp_MessageEx @sql;
						execute sp_executesql @sql,N'@nodeDispName varchar(1000) output',@nodeDispName  output;
						insert into #PortfolioStatus values (@batchJobKey, @demandSurge, @frequency, @eventType, @nodeDispName, @status);
					end
				else if @nodeType = 12
					begin
						set @sql = 'select @nodeDispName = longname, @status = ' + @dbName + '..FldrInfo.Status from ' + @dbName + '..FldrInfo inner join commondb..BatchJob BatchJob on Folder_Key=BatchJob.FolderKey and BatchJobKey= ' + dbo.trim(cast(@batchJobKey as varchar(20)));
						execute sp_executesql @sql,N'@nodeDispName varchar(1000) output, @status varchar(50) output', @nodeDispName  output, @status  output;
						insert into #PortfolioStatus values (@batchJobKey, @demandSurge, @frequency, @eventType, @nodeDispName, @status);
					end
				else if @nodeType = 101
					begin
						set @sql = 'select @nodeDispName = longname, @status = ' + @dbName + '..RdbInfo.Status from ' + @dbName + '..RdbInfo inner join commondb..BatchJob BatchJob on RdbInfo.RdbInfoKey=BatchJob.RdbInfoKey and BatchJobKey= ' + dbo.trim(cast(@batchJobKey as varchar(20)));
						execute sp_executesql @sql,N'@nodeDispName varchar(1000) output, @status varchar(50) output', @nodeDispName  output, @status  output;
						insert into #PortfolioStatus values (@batchJobKey, @demandSurge, @frequency, @eventType, @nodeDispName, @status);
					end
			end
		end
		fetch next from cursBatchJob into @batchJobKey, @dbName;
	end
	close cursBatchJob
	deallocate cursBatchJob

	select distinct BatchJobKey , DemandSurge, Frequency , EventType , NodeDisplayName , Status from #PortfolioStatus where Status in ('Active');
end
