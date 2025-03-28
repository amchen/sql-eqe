if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_UpdateReportRecordCountForRDB') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_UpdateReportRecordCountForRDB
end
 go

create procedure absp_UpdateReportRecordCountForRDB @rdbInfoKey int, @debug int=1
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:       The procedure updates the report record counts for all report types 
			   excluding ELT reports and exposure reports for   RDB.
			    
Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/
begin
	set nocount on
	
	declare @sql nvarchar(max);
		
	declare @sql2 varchar(max);
	declare @reportQuery varchar(6000);
	declare @pos int;
	declare @pos2 int;
	declare @YLTDBName varchar(150);
	declare @yltId int;
	declare @rdbAvailableReportKey int;
	declare @recCnt int;
	declare @reportId int;
	declare @reportType int;
	
	set @YLTDBName ='[' + DB_NAME() + ']';
				
	 set @sql2='select distinct  RDBAvailableReportKey, R2.ReportId,ReportTypeKey,ReportQuery, YltID from  RdbInfo R1  
					inner join dbo.RDBAvailableReport R2 on R1.RDBInfoKey=R2.RDBInfoKey     
					inner join ReportQuery R3 on R2.ReportID=R3.ReportID
					and R1.RDBInfoKey = ' +  CAST(@rdbInfoKey as varchar(10))
						
	if @debug=1 print @sql2;
	
	execute('declare RDBCurs cursor  global for '+@sql2)
	open RDBCurs
	fetch RDBCurs into @rdbAvailableReportKey, @reportId,@reportType,@reportQuery, @yltID;
	while @@fetch_status=0
	begin
		set @reportQuery=REPLACE (@reportQuery,'''''','''');
			
			--Fix the query to remove the 'order by' clause and 'top 20000 Col1, Col2'--
			set @pos = charindex(' from ', @reportQuery);
			set @pos2 = isnull(charindex(' order ', @reportQuery),LEN(@reportQuery));
			set @sql = 'select @recCnt= count(*) ' +  substring (@reportQuery,@pos,(@pos2 - @pos));
			
			--Add RDBName befor schemaName--
			--set @sql = replace(@sql,'dbo.',@YLTDBName + '.dbo.')
			--if @debug=1 print @sql		
           	
				set @sql=replace(@sql,'{0}',@yltId);
				
				--Execute count query--		
				if @debug =1 print @sql		
				execute sp_executesql @sql,N'@recCnt int output',@recCnt output; 
			

				set @sql = 'update ' + @YLTDBName + '.dbo.RDBAvailableReport
						set RecordCount=' + dbo.trim(cast(@recCnt as varchar(10)))+ 
						'	where RdbAvailableReportKey =' + cast ( @rdbAvailableReportKey as varchar(30)) 
						if @debug =1 print @sql		
					exec(@sql)
		
	fetch RDBCurs into @rdbAvailableReportKey,@reportId,@reportType,@reportQuery, @yltID;
	end
	close RDBCurs;
	deallocate RDBCurs;
end