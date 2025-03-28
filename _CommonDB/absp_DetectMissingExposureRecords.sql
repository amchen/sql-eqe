if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_DetectMissingExposureRecords') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_DetectMissingExposureRecords;
end
go

-------------------------------------------------------------------------------------------------------
-- NOTE: This procedure must be loaded and executed from the commondb database
-------------------------------------------------------------------------------------------------------

create procedure absp_DetectMissingExposureRecords
	@dbName varchar(120) = ''
as
BEGIN TRY

	declare @sql  varchar(max);
	declare @sql1 varchar(max);
	declare @sql2 varchar(max);
	declare @sql3 varchar(max);
	declare @sql4 varchar(max);
	declare @sql5 varchar(max);
	declare @sql6 varchar(max);
	declare @sql7 varchar(max);
	declare @sqlA varchar(max);
	declare @OriginalSourceName varchar(255);
	declare @CreateDate varchar(14);
	declare @expoKey1 int;
	declare @expoKey2 int;
	declare @NodeKey int;
	declare @NodeType int;
	declare @TableName varchar(120);
	declare @ExpectedCount int;
	declare @ActualCount int;
	declare @dbList   table (dbName varchar(120));

	-- check for commondb
	if not exists (select 1 from RQEVersion where DbType='COM')
	begin
		print 'NOTE: This procedure must be loaded and executed from the commondb database';
		return;
	end

	-- init
	if (@dbName = '')
		insert @dbList (dbName) select DB_NAME from CFldrInfo;
	else
		insert @dbList (dbName) values (@dbName);

	create table #temp1 (OriginalSourceName varchar(255), CreateDate varchar(14), Count int, ExposureKey int, MaxEK int);
	set @sql1 = 'insert into #temp1 select OriginalSourceName, CreateDate, COUNT(*) Count, MIN(ef.ExposureKey) ExposureKey, MAX(ef.exposurekey) MaxEK ' +
				'from ExposureFile ef, ExposureInfo ei ' +
				'where ef.ExposureKey = ei.ExposureKey and importstatus = ''Completed'' '+
				'group by OriginalSourceName, CreateDate ' +
				'having COUNT(*) > 1';

	create table #temp3 (OriginalSourceName varchar(255), CreateDate varchar(14), Count int, ExposureKey int, MaxEK int);
	set @sqlA = 'insert into #temp3 select OriginalSourceName, CreateDate, 2, @expoKey1, ef.ExposureKey MaxEK ' +
				'from ExposureFile ef, ExposureInfo ei ' +
				'where ef.ExposureKey = ei.ExposureKey ' +
				'  and OriginalSourceName=''@OriginalSourceName'' ' +
				'  and CreateDate=''@CreateDate'' ' +
				'  and ei.ExposureKey <> @expoKey1';

	create table #temp2 (NodeKey int, NodeType int, TableName varchar(120), ExpectedCount int, ActualCount int);
	set @sql2 = 'insert into #temp2 select e2.NodeKey,e2.NodeType,e2.TableName,e1.TotalCount ExpectedCount,e2.TotalCount ActualCount ' +
				'from ExposureCount e1 inner join ExposureCount e2 on e1.TableName = e2.TableName and e1.Category = e2.Category ' +
				'where e1.TotalCount <> e2.TotalCount ' +
				'and e1.ExposureKey=@expoKey1 ' +
				'and e2.ExposureKey=@expoKey2 ' +
				'order by e2.TableName';


	create table #temp4 (NodeKey int, NodeType int, ExposureKey int);
	set @sql4 = 'insert into #temp4 select em.ParentKey, em.ParentType, ef.ExposureKey ' +
				'from ExposureFile ef, ExposureInfo ei, ExposureMap em ' +
				'where ef.ExposureKey = ei.ExposureKey ' +
				'  and em.ExposureKey = ei.ExposureKey ' +
				'  and importstatus = ''Completed'' ' +
				'  and OriginalSourceName=''@OriginalSourceName'' ' +
				'  and CreateDate=''@CreateDate'' ' +
				'  and ei.ExposureKey <> @expoKey1';

	create table #portList (dbName varchar(120), portName varchar(120), NodeKey int, NodeType int, OriginalSourceName varchar(255), ExposureKey int, ExposureTable varchar(120), ExpectedCount int, ActualCount int);
	set @sql6 = 'update #portList set portName = LongName from #portList inner join @portTable on @portColumn = NodeKey where NodeType @NodeType';

	declare curDbList cursor fast_forward for select dbName from @dbList;
	declare curTemp1  cursor fast_forward for select OriginalSourceName, CreateDate, ExposureKey, MaxEK from #temp1;
	declare curTemp2  cursor fast_forward for select NodeKey, NodeType, TableName, ExpectedCount, ActualCount from #temp2;

	-- Process database
	open curDbList;
	fetch next from curDbList into @dbName;
	while @@FETCH_STATUS = 0
	begin

		truncate table #temp1;
		set @sql = 'USE [' + @dbName + ']; ' + @sql1;
		print @sql;
		execute(@sql);

		-- Get all related ExposureKeys
		truncate table #temp3;
		open curTemp1;
		fetch next from curTemp1 into @OriginalSourceName, @CreateDate, @expoKey1, @expoKey2;
		while @@FETCH_STATUS = 0
		begin

			set @sql3 = replace(@sqlA, '@expoKey1', cast(@expoKey1 as varchar(30)));
			set @sql3 = replace(@sql3, '@OriginalSourceName', @OriginalSourceName);
			set @sql3 = replace(@sql3, '@CreateDate', @CreateDate);
			set @sql = 'USE [' + @dbName + ']; ' + @sql3;
			print @sql;
			execute(@sql);

			fetch next from curTemp1 into @OriginalSourceName, @CreateDate, @expoKey1, @expoKey2;
		end
		close curTemp1;

		insert #temp1 select * from #temp3;

		-- Process copied Exposure
		open curTemp1;
		fetch next from curTemp1 into @OriginalSourceName, @CreateDate, @expoKey1, @expoKey2;
		while @@FETCH_STATUS = 0
		begin

			truncate table #temp2;
			set @sql3 = replace(@sql2, '@expoKey1', cast(@expoKey1 as varchar(30)));
			set @sql3 = replace(@sql3, '@expoKey2', cast(@expoKey2 as varchar(30)));
			set @sql = 'USE [' + @dbName + ']; ' + @sql3;
			print @sql;
			execute(@sql);

			-- Missing Exposure records
			open curTemp2;
			fetch next from curTemp2 into @NodeKey, @NodeType, @TableName, @ExpectedCount, @ActualCount;
			while @@FETCH_STATUS = 0
			begin
/*
				truncate table #temp4;
				set @sql5 = replace(@sql4, '@expoKey1', cast(@expoKey1 as varchar(30)));
				set @sql5 = replace(@sql5, '@OriginalSourceName', @OriginalSourceName);
				set @sql5 = replace(@sql5, '@CreateDate', @CreateDate);
				set @sql = 'USE [' + @dbName + ']; ' + @sql5;
				print @sql;
				execute(@sql);

				if @@rowcount > 0
				begin
					insert #portList (dbName, portName, NodeKey, NodeType, OriginalSourceName, ExposureKey, ExposureTable, ExpectedCount, ActualCount)
						select @dbName, '', NodeKey, NodeType, @OriginalSourceName, ExposureKey, @TableName, @ExpectedCount, @ActualCount
						  from #temp4;
				end
*/
				insert #portList (dbName, portName, NodeKey, NodeType, OriginalSourceName, ExposureKey, ExposureTable, ExpectedCount, ActualCount) values
								 (@dbName, '', @NodeKey, @NodeType, @OriginalSourceName, @expoKey2, @TableName, @ExpectedCount, @ActualCount);

				fetch next from curTemp2 into @NodeKey, @NodeType, @TableName, @ExpectedCount, @ActualCount;
			end
			close curTemp2;

			fetch next from curTemp1 into @OriginalSourceName, @CreateDate, @expoKey1, @expoKey2;
		end
		close curTemp1;

		-- Populate Primary portName
		set @sql7 = replace(@sql6, '@portTable', 'PprtInfo');
		set @sql7 = replace(@sql7, '@NodeType', '= 2');
		set @sql7 = replace(@sql7, '@portColumn', 'Pport_Key');
		set @sql = 'USE [' + @dbName + ']; ' + @sql7;
		print @sql;
		execute(@sql);

		-- Populate Program Name
		set @sql7 = replace(@sql6, '@portTable', 'ProgInfo');
		set @sql7 = replace(@sql7, '@NodeType', 'in (7,27)');
		set @sql7 = replace(@sql7, '@portColumn', 'Prog_Key');
		set @sql = 'USE [' + @dbName + ']; ' + @sql7;
		print @sql;
		execute(@sql);

		fetch next from curDbList into @dbName;
	end
	close curDbList;
	deallocate curDbList;
	deallocate curTemp2;
	deallocate curTemp1;

	select distinct * from #portList order by 1,2,4,3;

END TRY

BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH
