if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_QA_TestInvalidation') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_QA_TestInvalidation 
end
 go

create procedure absp_QA_TestInvalidation  @ShowAllRows int=1
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:       The procedure will return the recordcount for all the tables 
				so as to validate the  TableList entries. 
				
				While testing the procedure, portfolios need to be created, analysed
				and invalidated in a fresh database.
				
Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/

begin  
	set nocount on
	declare @dbName varchar(120);
	declare @sql varchar(max);
	
	set @dbName=DB_NAME()+ '_IR';
	
	exec absp_getDBName @dbName out,@dbName;
	
	--create temp tables--
	create table #FinalRowCount (TableName varchar(130)  COLLATE SQL_Latin1_General_CP1_CI_AS, EDBCount int,IDBCount int);
	create table #RowCnt (TableName varchar(130)  COLLATE SQL_Latin1_General_CP1_CI_AS,  RCount int );
	create table #TblList (TableName varchar(130) COLLATE SQL_Latin1_General_CP1_CI_AS);
	insert into #TblList
		Select TableName from DictTbl where TableType in ('Event Loss Tables' , 'Binary Result', 'Reports (Analysis)', 'Reports (Exposure)') order by TableName

	---Check if background deletion (exposure) is complete---
	while (1=1)
	begin
		if not exists (select * from ELTSummary where Status='Deleted')
			break;
		exec absp_Util_Sleep 5000;

	end
	
	--Count entries for EDB--
	insert into #RowCnt exec absp_QA_ReturnRowCount;
	insert into #FinalRowCount (TableName, EDBCount) select TableName,RCount from #RowCnt;
	
	--Count entries for IDB--
	delete from #RowCnt;
	set @sql = 'insert into #RowCnt exec ' + @dbName + '..absp_QA_ReturnRowCount';
	exec (@sql);
	
	update #FinalRowCount set IDBCount=RCount 
		from #FinalRowCount A inner join #RowCnt B
		on A.TableName =B.TableName;
	
	set @sql='select * from #FinalRowCount'
	if @ShowAllRows <>1	set @sql = @sql + ' where ( EDBCount>0 or IDBCount>0 )'
	set @sql=@sql +  ' order by TableName'
	exec(@sql);
	
end