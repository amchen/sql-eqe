if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_GetSnapshotResults') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_GetSnapshotResults
end
go

create procedure absp_Migr_GetSnapshotResults @snapshotKey int, @reportTypeKey int, @nodeKey int,@nodeType int, @exposureKey int=0,@parentAccountKey int=0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure will get the Snapshot reports based on the reportType key.

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

*/
as
begin

	set nocount on
	
	declare @schemaname varchar(255);
	declare @sql nvarchar(max);
	declare @sql1 nvarchar(max);
	declare @rqeVersion varchar(25);
	declare @version varchar(25);
	declare @inList varchar(max);
	declare @columnName varchar(120);
	declare @reportId int;
	declare @availableReportKey int;
	declare @reportTypeKeyInList varchar(20);
	declare @layoutFileName varchar(256);
	declare @columnExists int;
	
	set @schemaName= dbo.trim('Snapshot_' + dbo.trim(cast(@snapShotKey as varchar(10))));
	select @rqeVersion = RQEVersion from SnapshotInfo where SnapshotKey=@snapshotKey;
	set @version=@rqeVersion;
	
	create table #Tmp_SnapshotQry (AvailableReportKey int, 
					AnalysisRunKey int,
					ReportId int, 
					ReportTypeKey int, 
					ReportQuery varchar(6000) COLLATE SQL_Latin1_General_CP1_CI_AS,
					LayoutFileName varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS,
					EBERunId int,
					EltStatus varchar(50),
					FinishDate varchar(14));

	create index #Tmp_SnapshotQry_I1 on #Tmp_SnapshotQry(AvailableReportKey);

	
	select @columnName = Case @nodeType
		when 0  then 'FolderKey'
		when 1  then 'AportKey'
		when 2  then 'Pportkey'
		when 4  then 'AccountKey'
		when 8  then 'PolicyKey'
		when 9  then 'SiteKey'
		when 23 then 'RPortKey'
		when 27 then 'ProgramKey'
		when 30 then 'CaseKey'
		when 64 then 'ExposureKey'
	else ''
	end;
	
	--Get analysisRunKeys--
	set @sql = 'select AnalysisRunKey from ' + @schemaname + '.AnalysisRunInfo where NodeType=' + dbo.trim(cast(@nodeType as varchar(10))) + ' and ' + @columnName + '=' + dbo.trim(cast(@nodeKey as varchar(10)));				
	if @nodeType=9	set @sql = @sql + ' and ExposureKey = ' + dbo.trim(cast(@exposureKey as varchar(10))) +  ' and accountKey=' + dbo.trim(cast(@parentAccountKey as varchar(10))) 
	exec absp_util_GenInList @inList out,@sql,'N';
	
	if @inList='in ( -2147000000 )' return; --No analysisRunKey found
	
	if @reportTypeKey = 2 --as passed tp procedure
		set @reportTypeKeyInList = ' in (3,4)';
	else
		set @reportTypeKeyInList = ' in (' + dbo.trim(cast(@reportTypeKey as varchar(10)))+ ')';
	
	--Get all reportIds for the node--
	set @sql= 'insert into #Tmp_SnapshotQry (AnalysisRunKey,AvailableReportKey, ReportId) 
				select AnalysisRunKey,AvailableReportKey, ReportId from ' + @schemaname + '.AvailableReport where AnalysisRunKey ' + @inList;
	exec(@sql)
	
	--Fixed defect 8564
	--Get version from snapshot query
	set @sql='select top (1) @rqeVersion=RqeVersion from SnapshotQuery where RqeVersion>=''' + @rqeVersion + '''  and ReportTypekey ' + @reportTypeKeyInList + ' order by RqeVersion ';
	exec sp_executesql @sql,N'@rqeVersion varchar(25) out',@rqeVersion out
	
	--Get ReportQuery and Layoutfilename from Sanpshotquery--
	set @sql= 'update #Tmp_SnapshotQry set  
					ReportTypeKey = T2.ReportTypeKey, ReportQuery=T2.ReportQuery,LayoutFileName=T2.LayoutFileName 
					from #Tmp_SnapshotQry T1 inner join SnapShotQuery T2 ' +
					' on T1.ReportId=T2.ReportId '+
			       ' where T2.RqeVersion=''' + @rqeVersion + '''  and T2.ReportTypekey ' + @reportTypeKeyInList 
	exec(@sql) 
	
	--get Layoutfilename from Report query if it is not in Sanpshotquery--
	set @sql= 'update #Tmp_SnapshotQry set  
					LayoutFileName=T2.LayoutFileName 
					from #Tmp_SnapshotQry T1 inner join  ReportQuery T2 ' +
					' on T1.ReportId=T2.ReportId '+
			        ' where  T2.ReportTypekey ' + @reportTypeKeyInList + 
			        ' and T1.LayoutFileName is NULL ' +
			        ' and not T1.ReportQuery is  NULL'
	exec(@sql) 
		
	--If SnapshotQuery entry does not exist get it from ReportQuery--
	set @sql= 'update #Tmp_SnapshotQry set  
					ReportTypeKey = T2.ReportTypeKey , ReportQuery=T2.ReportQuery,LayoutFileName=T2.LayoutFileName 
					from #Tmp_SnapshotQry T1 inner join ReportQuery T2 ' +
					' on T1.ReportId=T2.ReportId '+
			       ' where  T2.ReportTypekey ' + @reportTypeKeyInList + 
			       ' and T1.ReportQuery is NULL'
	exec(@sql) 
	
	
	delete from #Tmp_SnapshotQry where ReportQuery is NULL;
	
	--Update ELTSummaryInfo--
	set @sql= 'update #Tmp_SnapshotQry set  
				EBERunID = T2.EBERunID , EltStatus=T2.Status,FinishDate=T2.Finish_Dat 
						from #Tmp_SnapshotQry T1 inner join ' +@schemaname + '.ELTSummary T2 ' +
						' on T1.AnalysisRunKey=T2.AnalysisRunKey and T1.ReportId=T2.ReportID';

	exec(@sql) 
	if @reportTypeKey=5--Elt
		delete from #Tmp_SnapshotQry where EbeRunId is NULL;
		
	set @sql= 'select distinct T2.ReportTypeKey, T2.ReportQuery, T2.LayoutFileName,T2.EBERunID,T2.EltStatus,T2.FinishDate, T1.*, T3.* '
	
	--Fixed defect 8610 - New column RQEVersion in AvailableReport from 14.00.00--
	set @columnExists=0;
	set @sql1='select @columnExists = 1 from sys.columns where object_id=OBJECT_id(''' + dbo.trim(@schemaname) +'.AvailableReport'') and name=''RQEVersion'''
	exec sp_executesql @sql1,N'@columnExists int out',@columnExists out
	
	if @columnExists=0
	begin
		set @sql=@sql + ',''' + @version +''' as RQEVersion';
	end
	
	set @sql= @sql + ' from ReportQuery T1 
			inner join #Tmp_SnapshotQry T2 on T1.ReportId=T2.ReportId
			inner join  ' + @schemaname + '.AvailableReport T3 on T2.AvailableReportKey=T3.AvailableReportkey order by T3.ReportDisplayName';

	exec (@sql);
end