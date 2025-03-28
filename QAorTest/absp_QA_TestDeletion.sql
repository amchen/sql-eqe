if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_QA_TestDeletion') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_QA_TestDeletion
end
 go

create procedure absp_QA_TestDeletion 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:       The procedure will return the recordcount for all the tables 
				so as to validate the  DELCTRL entries. 
				It will check for the background deletion to be complete before 
				returning the rowcount.
				
				While testing the procedure, portfolios need to be created (and deleted)
				in a fresh database
.
Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/

begin  
	set nocount on
	
	declare @tableName varchar(120);
	declare @sql varchar(max);
	declare @dbName varchar(120);
	
	set @dbName=DB_NAME()+ '_IR';
	exec absp_getDBName @dbName out,@dbName;

	--wait till background deletion is complete
	exec absp_QA_CheckBackgroundDeletion;	

	--create temp tables--	
	create table #FinalRowCount (TableName varchar(130)  COLLATE SQL_Latin1_General_CP1_CI_AS, FreshDBCount int,EDBCount int,IDBCount int);
	create table #RowCnt (TableName varchar(130)  COLLATE SQL_Latin1_General_CP1_CI_AS,  RCount int );
	create table #TblList (TableName varchar(130) COLLATE SQL_Latin1_General_CP1_CI_AS);
		
	--create list of tables which are to be excluded --
	insert into #TblList  select TableName from DictTbl A inner join Sysobjects B on A.TableName=B.name
			where (CF_DB in('Y','L') or CF_DB_IR in('Y','L'))
			and TableType not in('MigrationVer13') and TableName not in('AnalysisRuninfo','LineOfBusiness','SubstitutionUsed');

	insert into #FinalRowCount(TableName,FreshDBCount) select TableName,0 from #TblList ;

	update #FinalRowCount set FreshDBCount =21 where TableName='BNL';
	update #FinalRowCount set FreshDBCount =1 where TableName='Branch'
	update #FinalRowCount set FreshDBCount =1 where TableName='ClassOfBusiness'
	update #FinalRowCount set FreshDBCount =10 where TableName='CNL'
	update #FinalRowCount set FreshDBCount =2 where TableName='Cobl'
	update #FinalRowCount set FreshDBCount =1 where TableName='Company'
	update #FinalRowCount set FreshDBCount =1 where TableName='CrolInfo'
	update #FinalRowCount set FreshDBCount =1 where TableName='CurrInfo'
	update #FinalRowCount set FreshDBCount =15 where TableName='D0308'
	update #FinalRowCount set FreshDBCount =1 where TableName='Division'
	update #FinalRowCount set FreshDBCount =16 where TableName='DNL'
	update #FinalRowCount set FreshDBCount =23 where TableName='ExceedanceRP' 
	update #FinalRowCount set FreshDBCount =112 where TableName='ExchRate'
	update #FinalRowCount set FreshDBCount =1 where TableName='LineOfBusiness'
	update #FinalRowCount set FreshDBCount =23 where TableName='Lobl'
	update #FinalRowCount set FreshDBCount =12 where TableName='NEPExced'
	update #FinalRowCount set FreshDBCount =17 where TableName='Patsl'
	update #FinalRowCount set FreshDBCount =8 where TableName='PolicyStatus'
	update #FinalRowCount set FreshDBCount =7 where TableName='PPL'
	update #FinalRowCount set FreshDBCount =5 where TableName='Rbil'
	update #FinalRowCount set FreshDBCount =1 where TableName='RBroker'
	update #FinalRowCount set FreshDBCount =1 where TableName='Reinsurer' 
	update #FinalRowCount set FreshDBCount =1 where TableName='RGroup'
	update #FinalRowCount set FreshDBCount =470 where TableName='Ril'
	update #FinalRowCount set FreshDBCount =4 where TableName='RPrgStat'
	update #FinalRowCount set FreshDBCount =1 where TableName='SummaryRP'
	update #FinalRowCount set FreshDBCount =1 where TableName='TreatyTag'
	update #FinalRowCount set FreshDBCount =1 where TableName='RQEVersion'
	update #FinalRowCount set FreshDBCount =1 where TableName='StreetGeocoder'
	update #FinalRowCount set FreshDBCount =10 where TableName='AnalCfig'
	update #FinalRowCount set FreshDBCount =2 where TableName='FldrInfo'
	update #FinalRowCount set FreshDBCount =1 where TableName='FldrMap'
-- 0011534: AnalysisModelSelection has been added to the delete pport invalidation output
	update #FinalRowCount set FreshDBCount =3 where TableName='AnalysisModelSelection'

	--Count entries for EDB--
	insert into #RowCnt exec absp_QA_ReturnRowCount;	
	update #FinalRowCount set EDBCount=RCount 
		from #FinalRowCount A inner join #RowCnt B
		on A.TableName =B.TableName;
 
 	----Count entries for IDB--
	delete from #RowCnt;
	set @sql = 'insert into #RowCnt exec ' + @dbName + '..absp_QA_ReturnRowCount';
	exec (@sql);
	
	 
	update #FinalRowCount set IDBCount=RCount 
		from #FinalRowCount A inner join #RowCnt B
		on A.TableName =B.TableName;
	 
	
	set @sql='select * from #FinalRowCount where (EdbCount<>FreshDBCount or (EdbCount<>IDBCount and IDBCount>0))'
	set @sql=@sql +  ' order by TableName'
	exec(@sql);
	 
end