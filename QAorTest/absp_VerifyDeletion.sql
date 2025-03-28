if exists(select 1 FROM SYSOBJECTS WHERE id = object_id(N'absp_VerifyDeletion') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_VerifyDeletion
end
go

create procedure absp_VerifyDeletion  @dbType char(3) = 'EDB'

as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:	This procedure will be called by QA to verify if the background deletion is working properly or not.
		The idea is to create an APort and have a PPort and RPort under it. Import and analyze at all node level.
		Delete the APort then call this procedure. This procedure will wait for the APort to get deleted by the background
		process and then get count from all the tables to check where all the records got deleted or not.
		The procedure will return a list of all the tables and count where there are records. It will exclude tables that are
		in 'Configurables', 'Process Control', 'System'.

Returns:	ResultSet
		The resultset will contain TableName and Count.

====================================================================================================
</pre>
</font>
##BD_END

*/
begin


declare @isDeleted int;
declare @curs_TblName char(100);
declare @cnt int;
declare @sql1 nvarchar(max);
declare @query varchar(max);
declare @tableName char(120);

set @sql1 = '';
set @isDeleted = 1;
select @isDeleted = 0 from AprtInfo where APort_Key = 3
print @isDeleted;

create table #TMP_TABLEWITHREC (TableName char(100), Cnt int);

if (@dbType = 'EDB')
begin
	-- Wait for the Aport to get deleted via the background process.
	while (@isDeleted = 0)
	begin
		exec absp_Util_Sleep 30000;
		set @isDeleted = 1;
		select @isDeleted = 0 from AprtInfo where APort_Key = 3
		if (@isDeleted = 0)
			print 'Wait for another 30 secs.'
		else
			break;

	end

	-- Now get the count of all the EDB tables where we expect the records to be deleted.
	insert into #TMP_TABLEWITHREC SELECT distinct OBJECT_NAME(p.object_id) AS [Table], p.rows AS [Row Count]
	FROM sys.partitions p
	inner join dicttbl on OBJECT_NAME(p.object_id) = TableName and Cf_DB = 'Y'
			   and TableType not in ('Configurables', 'Process Control', 'System', 'Binary Result')
			   and TableName not in ('SubstitutionUsed')
	ORDER BY [Table]
end

-- Now for the Binary Result table types the records are marked as -negative so we need to get the count separately

declare curs cursor fast_forward for
       select 'select @cnt = count(*) from ' + tablename + ' where ' + fieldname  + ' > 0', tablename from DictCol
		where TableType = 'Binary Result' and tablename not in ('IntDamageByCover','IntDamageByEvent','IntHazard')
		and FieldName in ('Aport_key', 'PPort_key','RPort_key', 'Prog_key', 'Case_Key', 'ExposureKey', 'AccountKey','SiteKey', 'StructureKey', 'PolicyKey')
	open curs
	fetch next from curs into @query, @tableName
	while @@fetch_status = 0
	begin
		set @sql1 = @query;

		execute sp_executesql @sql1,N'@cnt int output', @cnt output;

		insert into #TMP_TABLEWITHREC values (@tableName, @cnt);
		fetch next from curs into @query, @tableName
	end
	close curs
	deallocate curs

-- Now there are some tables where we create a separate partitioned table based on some key. Those tables are supposed to get
-- dropped once the node is deleted. Check for those.

if (@dbType = 'IDB')
begin
	insert into #TMP_TABLEWITHREC SELECT distinct OBJECT_NAME(p.object_id) AS [Table], p.rows AS [Row Count]
		FROM sys.partitions p
		where OBJECT_NAME(p.object_id) like 'IntDamageByCover_%'
		   or OBJECT_NAME(p.object_id) like 'IntDamageByEvent_%'
		   or OBJECT_NAME(p.object_id) like 'IntHazard_%'
		ORDER BY [Table];
end


-- Return the resultset
select * from #TMP_TABLEWITHREC order by cnt desc;

end
