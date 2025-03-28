if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetResultsDiffData') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetResultsDiffData
end
 go

create procedure absp_GetResultsDiffData @sessionID int, @whereClause  varchar(max), @orderByClause varchar(max), @pageNum  int=1, @pageSize int=1000, @debug int =0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	The procedure will compare reports from 
		- Two different nodes of the same type
		- Compare same type of reports within the same nodes
		- Compare reports from a Snapshot view
		- Compare reports between comparable report types

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

*/
as
begin
	set nocount on
	declare @rowCnt int;
	declare @pgNum int;
	declare @startRowNum int;
	declare @endRowNum int;
	declare @resultsComparisonTable varchar(100);
	declare @sql varchar(max);
	declare @tmpTbl varchar(130);
	declare @colNames varchar(max);
	
	set @resultsComparisonTable='FinalResultsComparisonTbl_'+ dbo.trim(cast(@sessionId as varchar(30)))
	if not exists(select 1 from sys.tables where name=@resultsComparisonTable) 
		return
		
	--Get the rows in a temp table--	
	set @tmpTbl='TmpResComp' + dbo.trim(cast(@sessionId as varchar(30)))
	set @colNames='';
	select @colNames= @colNames +  sc.Name + ',' from sysobjects so inner join syscolumns sc on sc.id = so.id
						where so.name = @resultsComparisonTable	order by sc.ColID	
	set @colNames=left(@colNames,len(@colNames)-1)
	set @colNames=replace(@colNames,'RowNum,','')
				
	set @sql = 'select IDENTITY(int, 1, 1) AS RowNum,' + @colNames + ' into ' + @tmpTbl + ' from ' + @resultsComparisonTable 
	
	-- replace whereClause 'XXX%' with 'All Countries%' because FinalResultsComparisonTbl stores COUNTRY_ID_A='All Countries'
	set @whereClause = REPLACE(@whereClause,'XXX%','All Countries%')
	
	if len(@whereClause) >0 set @sql = @sql + ' where ' + @whereClause 
	if len(@orderByClause) >0 set @sql = @sql + ' order by ' + @orderByClause 
	
	--if @debug=1 exec absp_MessageEx @sql
	exec(@sql)
	
	--Calculate rowNum to be displayed from--
	select  @rowCnt= ROWCNT  from SYSINDEXES where ID=object_id(@tmpTbl) and INDID<2;
	set @pgNum=@rowCnt /@pageSize;
	if @rowCnt % @pageSize >0 set @pgNum=@pgNum +1
	if @pgNum<@pageNum set @pageNum=1
 
	set @startRowNum = ((@pageNum - 1) * @pageSize) + 1
	set @endRowNum = @startRowNum + @pageSize	

	-- return total rowncount
	select @rowCnt as ROWCNT
	-- return list of column names and types
	SELECT column_name 'ColumnName', data_type 'DataType'
	FROM information_schema.columns
	WHERE table_name = @tmpTbl

	--Display a page from the temp table--
	set @sql='select * from ' + @tmpTbl + '  where RowNum>=' + dbo.trim(cast(@startRowNum as varchar(30))) + ' and RowNum<' + dbo.trim(cast(@endRowNum as varchar(30))) 
	--if @debug=1 exec absp_MessageEx @sql
	exec(@sql)
	
	--Drop temp table--
	if exists(select 1 from sys.tables where name=@tmpTbl) exec('drop Table ' + @tmpTbl)
end

