if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_getRDBListForQVReport') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_getRDBListForQVReport
end
 go

create procedure absp_getRDBListForQVReport  @nodeKey int, @nodeType int
as
begin 
	set nocount on
	
	declare @sql varchar(max);
	declare @sql1 varchar(max);
	declare @nodeKeyFieldName varchar(100);
	declare @YLTDBName varchar(254);
	declare @selectedMetrics varchar(254);
	
	create table #RDBList (RDBName varchar(254), SelectedMetrics varchar(254), ResultType char(1), TableName varchar(100), RDBInfoKey int, YLTID int, CreateDate varchar(14));
	
	if (@nodeType = 1)
		set @nodeKeyFieldName = 'APortKey';
	else if (@nodeType = 2)
		set @nodeKeyFieldName = 'PPortKey';	
	else if (@nodeType = 23)
		set @nodeKeyFieldName = 'RPortKey';
	else if (@nodeType = 27)
		set @nodeKeyFieldName = 'ProgramKey';
	else if (@nodeType = 30)
		set @nodeKeyFieldName = 'CaseKey';	
	
	set @sql = 'select distinct YLTDatabaseName, YLTSelectedMetrics from AnalysisRunInfo where ' + @nodeKeyFieldName  + ' = ' + cast(@nodeKey as varchar(10)) +
						 ' and len(YLTDatabaseName) > 0 and AnalysisRunKey in (select distinct AnalysisRunKey from AvailableReport)';
	print @sql;
	
	execute('declare cursYLTDBName cursor forward_only global  for ' + @sql)
	open cursYLTDBName
	fetch next from cursYLTDBName into @YLTDBName,@selectedMetrics
	while @@fetch_status = 0
	begin

		IF EXISTS (SELECT name FROM master.sys.databases WHERE name = @YLTDBName)
		begin
			if OBJECT_ID('tempdb..#TMP1') is not null
    				drop table #TMP1;
	    			
			create table #TMP1 (YLTID int, RdbInfoKey int, ResultType char(1), CreateDate varchar(14));
			
			set @sql1 = ' insert into #TMP1 select YLTID, yltsummary.RDBINFOKEY, ResultType, Createdate  from [' + @YLTDBName + ']..YLTSummary ' + 
					' inner join [' + @YLTDBName + ']..rdbinfo on YLTSummary.RdbInfoKey = RdbInfo.RdbInfoKey ' + 
					' and  SourceNodeKey = ' + cast(@nodeKey as varchar) + ' and SourceNodeType = ' + cast (@nodeType as varchar);
			print @sql1;
			execute (@sql1);

			set @sql1 = ' insert into #RDBList ' + 
					' select distinct ''' + @YLTDBName + ''', ''' + @selectedMetrics + ''', YLTSummary.ResultType, YLTSummary.TableName, YLTSummary.RDBInfoKey, YLTSummary.YltID, Createdate from [' + @YLTDBName + ']..YLTSummary ' +  
						' inner join #TMP1 on YLTSummary.RdbInfoKey=#TMP1.RdbInfoKey where YLTSummary.RdbInfoKey in (select MAX (#TMP1.rdbinfokey) from #TMP1 where ResultType = ''P'') ' + 
						' union ' + 
					' select distinct ''' + @YLTDBName + ''', ''' + @selectedMetrics + ''', YLTSummary.ResultType, YLTSummary.TableName, YLTSummary.RDBInfoKey, YLTSummary.YltID, Createdate from [' + @YLTDBName + ']..YLTSummary ' +
						' inner join #TMP1 on YLTSummary.RdbInfoKey=#TMP1.RdbInfoKey where YLTSummary.RdbInfoKey in (select MAX (#TMP1.rdbinfokey) from #TMP1 where ResultType = ''L'') ';
					
			execute (@sql1);
		end
		fetch next from cursYLTDBName into @YLTDBName,@selectedMetrics
	end
	close cursYLTDBName
	deallocate cursYLTDBName
	
	select * from #RDBList;
	
end	

