if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_AttachShrinkDetachDatabase') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_AttachShrinkDetachDatabase
end
go

create procedure absp_Util_AttachShrinkDetachDatabase
    @dbName varchar(255),
	@dbPath varchar(254),
	@dbLogPath varchar(254),
	@shrinkFlag int=0

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure attaches a database, shrinks the data and log files, then detaches the database.
Returns:    Successful or error messages
====================================================================================================
</pre>
</font>
##BD_END

##PD  @dbName ^^  database name
##PD  @dbPath ^^  full MDF database path EXCLUDING the database name
##PD  @dbLogPath ^^  full LDF log path EXCLUDING the database name
##PD  @shrinkFlag ^^  0 = Do not shrink, show information only
                      1 = Shrink database/log only
                      2 = Rebuild/Reorg index only
                      3 = Shrink database and index
*/

as
begin

	set nocount on;

    declare @msg varchar(255);
	declare @rc int;
	declare @dbFreeSpace int;
	declare @idxRebuild int;
	declare @idxReorg int;
	declare @sql nvarchar(max);
	declare @PercentFreeSpace int;
	declare @indexInfo table (TableName varchar(100),
							  IndexName varchar(100),
							  FragPercent int);

	-- Set threshold percentage
	set @dbFreeSpace = 30;
	set @idxRebuild = 30;
	set @idxReorg = 10;

	begin try

		-- Physically attach the database
		exec @rc = absp_Util_AttachDatabase
						@msg output,
						@dbName,
						@dbPath,
						@dbLogPath,
						@attachNoLog = 0;

		if (@rc = 0)
		begin

			-- Check for free space in database
			set @PercentFreeSpace = 0;
			set @sql = N'USE [' + @dbName + ']; SELECT @PercentFreeSpace = ((size/128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0) / (size/128.0)) * 100 FROM sys.database_files where file_id=1;';
			print @sql;
			execute sp_executesql @sql,N'@PercentFreeSpace int output',@PercentFreeSpace output;

			-- Shrink datafile
			if (@PercentFreeSpace >= @dbFreeSpace)
			begin
				set @sql = @dbName + ': The mdf has ' + cast(@PercentFreeSpace as varchar) + '% free space. Shrinking is required.';
				print @sql;
				set @sql = N'USE [' + @dbName + ']; DBCC SHRINKFILE(2, 1, TRUNCATEONLY) WITH NO_INFOMSGS;';
				print @sql;
				if (@shrinkFlag in (1,3)) exec (@sql);
				set @sql = N'DBCC SHRINKDATABASE([' + @dbName + ']);';
				print @sql;
				if (@shrinkFlag in (1,3)) exec (@sql);
			end
			else
			begin
				set @sql = @dbName + ': The mdf has ' + cast(@PercentFreeSpace as varchar) + '% free space. Shrinking is not required.';
				print @sql;
			end

			-- Check for free space in log
			set @PercentFreeSpace = 0;
			set @sql = N'USE [' + @dbName + ']; SELECT @PercentFreeSpace = ((size/128.0 - CAST(FILEPROPERTY(name, ''SpaceUsed'') AS INT)/128.0) / (size/128.0)) * 100 FROM sys.database_files where file_id=2;';
			print @sql;
			execute sp_executesql @sql,N'@PercentFreeSpace int output',@PercentFreeSpace output;

			-- Shrink log
			if (@PercentFreeSpace >= @dbFreeSpace)
			begin
				set @sql = @dbName + ': The log has ' + cast(@PercentFreeSpace as varchar) + '% free space. Shrinking is required.';
				print @sql;
				set @sql = N'USE [' + @dbName + ']; DBCC SHRINKFILE(2, 2, TRUNCATEONLY) WITH NO_INFOMSGS;';
				print @sql;
				if (@shrinkFlag in (1,3)) exec (@sql);
			end
			else
			begin
				set @sql = @dbName + ': The log has ' + cast(@PercentFreeSpace as varchar) + '% free space. Shrinking is not required.';
				print @sql;
			end

			-- Rebuild or Reorg indicies
			set @sql = N'USE [' + @dbName + ']; ';
			set @sql = @sql + N'SELECT OBJECT_NAME(i.OBJECT_ID) AS TableName, i.name AS IndexName, indexstats.avg_fragmentation_in_percent ';
			set @sql = @sql + N'FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, ''SAMPLED'') indexstats INNER JOIN sys.indexes i ';
			set @sql = @sql + N'ON i.OBJECT_ID = indexstats.OBJECT_ID AND i.index_id = indexstats.index_id ';
			set @sql = @sql + N'INNER JOIN sys.objects o ON indexstats.object_id = o.object_id INNER JOIN sys.schemas s ON s.schema_id = o.schema_id ';
			set @sql = @sql + N'WHERE indexstats.avg_fragmentation_in_percent >= ' + cast(@idxReorg as varchar);
			set @sql = @sql + N' AND s.name = ''dbo''';
			set @sql = @sql + N' AND indexstats.page_count > 8 ';
			set @sql = @sql + N' AND i.name in (select IndexName from DictIdx)';
			print @sql;
			insert @indexInfo execute sp_executesql @sql;
			select * from @indexInfo;

			declare @RebuildIndexesSQL nvarchar(max);
			set @RebuildIndexesSQL = '';
			select @RebuildIndexesSQL = @RebuildIndexesSQL +
				case when [FragPercent] >= @idxRebuild
					 then char(10) + 'ALTER INDEX ' + quotename(IndexName) + ' ON ' + quotename( @dbName) + '.dbo.' + quotename(TableName) + ' REBUILD;'
					 else char(10) + 'ALTER INDEX ' + quotename(IndexName) + ' ON ' + quotename( @dbName) + '.dbo.' + quotename(TableName) + ' REORGANIZE;'
				end
				from @indexInfo;

			declare @StartOffset int;
			declare @Length int;
			set @StartOffset = 0;
			set @Length = 4000;
			while (@StartOffset < len(@RebuildIndexesSQL))
			begin
				set @sql = substring(@RebuildIndexesSQL, @StartOffset, @Length);
				print @sql;
				if (@shrinkFlag in (2,3)) exec (@sql);
				set @StartOffset = @StartOffset + @Length;
			end
		end
		else
		begin
			print @msg;
		end

		-- Physically detach the database
		exec absp_Util_DetachDB @dbName, 1;

	end try

	begin catch

		set @msg = 'Error in absp_Util_AttachShrinkDetachDatabase ' + @dbName + ': ' + ERROR_MESSAGE();
		if exists ( select 1 from sys.databases where name = @dbName )
		begin
			exec sp_detach_db @dbName;
		end

	end catch

	return @rc;
end
/*
exec absp_Util_AttachShrinkDetachDatabase
    @dbName='RQE13',
	@dbPath='D:\RQEDatabases\RQE13\RQE13 databases\EDB',
	@dbLogPath='D:\RQEDatabases\RQE13\RQE13 databases\EDB',
	@shrinkFlag=1;

exec absp_Util_AttachShrinkDetachDatabase
    @dbName='RQE13_IR',
	@dbPath='D:\RQEDatabases\RQE13\RQE13 databases\IDB',
	@dbLogPath='D:\RQEDatabases\RQE13\RQE13 databases\IDB'
	@shrinkFlag=2;
*/
