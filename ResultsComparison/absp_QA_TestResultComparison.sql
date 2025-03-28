if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_QA_TestResultComparison') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_QA_TestResultComparison
end
 go

create procedure absp_QA_TestResultComparison	@nodeType int,
						@reportType int,
						@baseFolderName varchar(255),
						@debug int=0
												
as
begin 
	set nocount on
	declare @dbName varchar(130);
	declare @columnName varchar(130);
	declare @reportQuery varchar(max);
	declare @reportQuery1 varchar(max);
	declare @reportQuery2 varchar(max);
	declare @reportId varchar(max);
	declare @sql nvarchar(max);
	declare @sql2 varchar(8000);
	declare @ebeRunID1 int;
	declare @ebeRunID2 int;
	declare @analysisRunKey1 int;
	declare @analysisRunKey2 int;
	declare @summaryRp int;
	declare @outFile varchar(255);	
	declare @tmpFile varchar(255);
	declare @exposureKey int;
	declare @accountKey int;
	declare @delimiter varchar(2);
	declare @xp_cmdshell_enabled int;
	
	set @delimiter='\t';
	exec @xp_cmdshell_enabled = absp_Util_IsUseXPCmdShell;

	set @dbName = DB_NAME();
	
	select @columnName = Case @nodeType
		when 1  then 'AportKey'
		when 2  then 'Pportkey'
		when 4  then 'Accountkey'
		when 9  then 'Sitekey'
		when 23 then 'RPortKey'
		when 27 then 'ProgramKey'
		when 30 then 'CaseKey'
		
	else ''	end
	
	if @reportType= 3 set @summaryRp=1 else set @summaryRp=0
	set @exposureKey=1;
	set @accountKey=1;
	
	set @sql ='select distinct b.reportId,reportQuery from analysisRunInfo A inner Join availablereport B
		on A.AnalysisRunKey=B.AnalysisrunKey
		inner join ReportQuery C on 
		B.ReportId=C.ReportID
		where ' + @columnName + '=1 and NodeType=' + CAST(@nodetype as varchar(10))+' and ReportTypeKey=' + CAST(@reportType as varchar(30)) +
		' and len(ReportQuery)>0'

	begin
		execute('declare curs cursor global for '+@sql )					
		open curs
		fetch curs into @reportId,@reportQuery
		while @@FETCH_STATUS = 0
		begin			
			set @reportQuery=replace(@reportQuery,'''''','''');
			if @reportType =5
			begin
					set @sql ='select top(1) @analysisRunKey1= A.AnalysisRunKey  from analysisRunInfo A inner Join availablereport B
						on A.AnalysisRunKey=B.AnalysisrunKey
						inner join ReportQuery C on 
						B.ReportId=C.ReportID
						where ' + @columnName + '=1 and NodeType=' + CAST(@nodetype as varchar(10))+' and ReportTypeKey=' + CAST(@reportType as varchar(30)) +
						' and len(ReportQuery)>0 order by A.AnalysisRunKey'
					exec sp_executesql @sql,N'@analysisRunKey1 int out',@analysisRunKey1 out
				
					set @sql ='select top(1) @analysisRunKey2= A.AnalysisRunKey  from analysisRunInfo A inner Join availablereport B
						on A.AnalysisRunKey=B.AnalysisrunKey
						inner join ReportQuery C on 
						B.ReportId=C.ReportID
						where ' + @columnName + '=1 and NodeType=' + CAST(@nodetype as varchar(10))+' and ReportTypeKey=' + CAST(@reportType as varchar(30)) +
						' and len(ReportQuery)>0 order by A.AnalysisRunKey desc'
						exec sp_executesql @sql,N'@analysisRunKey2 int out',@analysisRunKey2 out
					
				--for demand surge off
				select @ebeRunId1=ebeRunID from eltSummary where NodeKey=1 and NodeType= @nodeType  and analysisrunKey=@analysisRunKey1	and reportID=@reportID	
 				set @reportQuery1=replace(@reportQuery,'{0}',@ebeRunID1)
 				--for demand surge on
 				select @ebeRunId2= ebeRunId from eltSummary where NodeKey=1 and NodeType= @nodeType  and analysisrunKey=@analysisRunKey2 and reportID=@reportID	
 				set @reportQuery2=replace(@reportQuery,'{0}',@ebeRunID2)

			end
			else if @reportType =1
			begin
				--compare with itself--
 				set @reportQuery1=replace(replace(@reportQuery,'{0}',1),'{1}',@nodeType)
 				set @reportQuery2=@reportQuery1
			end
			else
			begin
				if @nodeType=4 --Account
				begin
					--{0} is NodeKey, {1} is ExposureKey, {2} is AccountKey, {3] is AnlCfg_Key
 					
 					set @reportQuery=replace(@reportQuery,'{0}',1)
 					set @reportQuery=replace(@reportQuery,'{1}',1)
 					set @reportQuery=replace(@reportQuery,'{2}',1)
 					set @reportQuery=replace(@reportQuery,'{4}',1)--CalcrID
 					set @reportQuery1=replace(@reportQuery,'{3}',0)--demand surge off
 					--for demand surge on
 					set @reportQuery2=replace(@reportQuery,'{3}',1)	
 					
				end
				else if @nodeType=9 --Site
				begin 
					--{0} is NodeKey, {1} is ExposureKey, {2} is AccountKey, {3} is SiteKey, {4] is AnlCfg_Key
 					--for demand surge off
 					set @reportQuery=replace(@reportQuery,'{0}',1)
 					set @reportQuery=replace(@reportQuery,'{1}',1)
 					set @reportQuery=replace(@reportQuery,'{2}',1)
 					set @reportQuery=replace(@reportQuery,'{3}',1)
 					set @reportQuery1=replace(@reportQuery,'{4}',0)
 					--for demand surge on
 					set @reportQuery2=replace(@reportQuery,'{4}',1)
				end 
				else
				begin
					--{0} is NodeKey, {1} is AnlcfgKey, {2} is CalcrId
					--for demand surge off
 					set @reportQuery=replace(replace(@reportQuery,'{0}',1),'{2}',1)
 					set @reportQuery1=replace(@reportQuery,'{1}',0)
 					--for demand surge on
 					set @reportQuery2=replace(@reportQuery,'{1}',1)
 				end			
 			end
 	
 			if @reportQuery1 is null or @reportQuery2 is null 
 			begin 
 				print 'Incorrect ReportQuery..'; 
 			end	
 			else
 			begin		

				exec absp_PerformResultComparison	1,
									@dbName,
									@reportID,
									@reportQuery1 ,
									@summaryRp,
									-1,
									@dbName,
									@reportID,
									@reportQuery2,
									@summaryRp,
									-1,
									1
				----------Get the Header info--------------
				set @outFile=@baseFolderName + '\' + dbo.trim(cast(@reportId as varchar(10)))+'.txt'
				set @sql2=''
										
				select @sql2= @sql2 +  sc.Name + '	' from sysobjects so inner join syscolumns sc on sc.id = so.id
						where so.name = 'FinalResultsComparisonTbl_1' 	order by sc.ColID
													
				set @sql2=left(@sql2,len(@sql2)-1)
 
				set @tmpFile=@baseFolderName + '\Tmp_' + dbo.trim(cast(@reportId as varchar(10)))+'.txt'

				if (@xp_cmdshell_enabled = 1)
				begin
					set @sql2='echo ' + @sql2+ ' >' + @outFile
					exec xp_cmdshell @sql2,no_output
				end
				else
				begin
					-- execute the command via CLR
					exec systemdb.dbo.clr_Util_WriteLine @outFile,@sql2,0;
				end
				-------------------------------------------
				-----------Write to Txt file---------------
			
				set @sql='select top (100) * from FinalResultsComparisonTbl_1'
				exec absp_Util_UnloadData 'Q',@sql,@tmpFile,@delimiter
				
				--In case we have 0 rows do not include header
				if (@xp_cmdshell_enabled = 1)
				begin
					if exists(select top(100) * from FinalResultsComparisonTbl_1)
						set @sql2='type ' + @tmpFile + ' >> ' + @outFile
					else
						set @sql2='type ' + @tmpFile + ' > ' + @outFile
					exec xp_cmdshell @sql2, no_output
				end
				else
				begin
					-- execute the command via CLR
					if exists(select top(100) * from FinalResultsComparisonTbl_1)
						exec systemdb.dbo.clr_Util_FileCopy @tmpFile, @outFile,0
					else
						exec systemdb.dbo.clr_Util_FileCopy @tmpFile, @outFile,1
					 
				end

			---------------------------------------------
				exec absp_Util_DeleteFile @tmpFile
			end
			fetch curs into  @reportId,@reportQuery
		end
		close curs
		deallocate curs
	 end
	 
	 if exists(select 1 from sys.tables where name='FinalResultsComparisonTbl_1')
		 drop table FinalResultsComparisonTbl_1
end


