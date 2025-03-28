if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_UpdateReportsAvailableColumn') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_UpdateReportsAvailableColumn
end
 go

create procedure absp_UpdateReportsAvailableColumn @nodeKey int,@nodeType int,@category varchar(50)
as
begin
	set nocount on
	declare @schemaName varchar(500)
	declare @sql varchar(max);
	declare @joinStr varchar(1000);
	
	if @category='Account' 
		set @joinStr=' B.SiteKey=0 '
	else 
		set @joinStr=' A.SiteKey=B.SiteKey '
		
	select schemaName into #SchemaName from snapshotinfo t1 
			inner join  snapshotmap t2
			on t1.SnapShotKey=t2.SnapshotKey 
			and t2.nodeKey=@nodeKey and t2.NodeType=@nodeType
			and Status='Available'
	union select 'dbo'			

		declare curSch cursor for select schemaName from #schemaName
		open curSch
		fetch curSch into @schemaName
		while @@fetch_status=0
		begin
			--Update ReportAvailable column
			set @sql='update #FinalFilterRecords
					set ReportsAvailable= 1 from #FinalFilterRecords A  inner join ' + @schemaName + '.AnalysisRunInfo B 
					on A.exposurekey=B.exposureKey and A.AccountKey=B.AccountKey and ' + @joinStr +
					' inner join ' + @schemaName + '.AvailableReport C 
					on B.AnalysisRunKey=C.AnalysisRunKey 
					and Status=''Available'' '
				print @sql
			exec( @sql)
			fetch curSch into @schemaName
		end
		close curSch
		deallocate curSch

end
	  
  
 


 
