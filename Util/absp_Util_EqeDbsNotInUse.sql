if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_EqeDbsNotInUse') and objectproperty(ID,N'isprocedure') = 1)
begin
 drop procedure absp_Util_EqeDbsNotInUse
end
go

create procedure absp_Util_EqeDbsNotInUse
	@daysNotTouched int = 15
as

/* 
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose: 

The procedure creates a temp table into which it stuff the names of EQE EDBs that have not been
used for a given number of days.  If days are not specified by user defaults to 15.

Examples
	exec absp_Util_EqeDbsNotInUse
	exec absp_Util_EqeDbsNotInUse 15

Returns:     recordset of dbName and last accessed date and days since touched

=================================================================================
</pre> 
</font> 
##BD_END 

##PD  @daysNotTouched ^^ The number of days that qualify as not used - default is 15.

*/

begin
DECLARE @name VARCHAR(500);
DECLARE @dbid int;
DECLARE @longName VARCHAR(500);
DECLARE @finishDate VARCHAR(500);
DECLARE @sql VARCHAR(1000);
declare @today datetime;

set @today = GETDATE();

IF OBJECT_ID('tempdb..#eqe_inuse','u') IS NOT NULL
	begin
		drop table #eqe_inuse;
	end;
create table #eqe_inuse(DBNAME VARCHAR(500), DBID int, DBType char(3), DbRefKey int, LastRunDate char(14), Days int, DetachCandidate bit); 


-- step 1. get a list of all attached databases
insert into #eqe_inuse
	SELECT name, dbid, '', 0, '', 0, 0 FROM MASTER.dbo.sysdatabases 
		WHERE name not like ('%_IR') and name not in ('master', 'model', 'msdb','tempdb', 'commondb','systemdb')

-- process each database we found
DECLARE db_cursor CURSOR FOR  
	SELECT DBNAME, DBID from #eqe_inuse order by 1;  

OPEN db_cursor;

FETCH NEXT FROM db_cursor INTO @name, @dbid ;
WHILE @@FETCH_STATUS = 0  
BEGIN  
	-- step 2.  determine the dbtype of each RQE database (using rqeversion as the link)
    set @sql = 'use [' + @name + '];' + 'IF OBJECT_ID (N''RQEVersion'', N''U'') IS NOT NULL ' +
				'update #eqe_inuse set DBType = (select top 1 DbType from RQEVersion) where #eqe_inuse.DBID = ' + cast(@dbid as CHAR(9));
	exec (@sql);

	-- step 3.  look into CFLDRINFO to see if logically attached or not
    set @sql = 'use [' + @name + '];' + 'IF OBJECT_ID (N''RQEVersion'', N''U'') IS NOT NULL ' +
				'update T1 set T1.DbRefKey = T2.cf_ref_key from #eqe_inuse T1 inner join CFLDRINFO T2 on T1.DBName = T2.LongName';
	exec (@sql);
	
	-- step 4.  get the max finish date from batchjob & preserve to see when last imported or analyzed
    set @sql = 'use [' + @name + '];' + 'IF OBJECT_ID (N''RQEVersion'', N''U'') IS NOT NULL ' + 
		'update T1 set T1.LastRunDate = (select max(X.FinishDate) from ' +
		' (select MAX(FinishDate) FinishDate from BatchJob inner join #eqe_inuse on BatchJob.DBRefKey = #eqe_inuse.DBRefKey and #eqe_inuse.DBID = ' + cast(@dbid as CHAR(9)) + 
		' union select max(FinishDate) FinishDate from BatchJobPreserve inner join #eqe_inuse on BatchJobPreserve.DBRefKey = #eqe_inuse.DBRefKey and #eqe_inuse.DBID = ' + cast(@dbid as CHAR(9)) +') X) ' +
		' from #eqe_inuse T1 where DBID = ' + cast(@dbid as CHAR(9));
	exec (@sql);
	
	-- step 5.  for anything not imported or analyzed, has it been updated?
	set @sql = 'use [' + @name + '];' + 'IF OBJECT_ID (N''RQEVersion'', N''U'') IS NOT NULL ' + 
		'update T1 set T1.LastRunDate = (select max(X.UsageDate) from ' +
		' (select convert(char(8), MAX(last_user_update),112)+replace(convert(char(8), MAX(last_user_update),108),'':'','''') UsageDate ' + 
		' FROM sys.dm_db_index_usage_stats WHERE [database_id] = DB_ID() AND OBJECTPROPERTY(object_id, ''IsMsShipped'') = 0' + ') X) ' +
		' from #eqe_inuse T1 where LastRunDate is null and DBID = ' + cast(@dbid as CHAR(9));
	exec (@sql);

	-- step 6.  figure out how long untouched
	set @sql = 'use [' + @name + '];' + 
		'update #eqe_inuse set Days = DATEDIFF(day, convert(datetime, ' +
		' SUBSTRING(LastRunDate, 1, 4) + ''-'' + SUBSTRING(LastRunDate, 5, 2) + ''-'' + SUBSTRING(LastRunDate, 7, 2) + '' '' + ' +
		' SUBSTRING(LastRunDate, 9, 2) + '':'' + SUBSTRING(LastRunDate, 11, 2)+ '':'' + SUBSTRING(LastRunDate, 13, 2), 20), ' +
		' getdate()) ' +
		' from #eqe_inuse where LEN(LastRunDate) > 0 ';
	exec (@sql);

	-- step 7. mark candidates
	set @sql = 'use [' + @name + '];' + 
		'update #eqe_inuse set DetachCandidate = 1 where Days > ' + CAST(@daysNotTouched as CHAR(5))
		
	exec (@sql);
	

	-- next db
    FETCH NEXT FROM db_cursor INTO @name, @dbid; 
END;

CLOSE db_cursor;
DEALLOCATE db_cursor;

select * from #eqe_inuse;

end
