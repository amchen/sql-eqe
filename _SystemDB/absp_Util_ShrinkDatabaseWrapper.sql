if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_ShrinkDatabaseWrapper') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_ShrinkDatabaseWrapper
end
go

create procedure absp_Util_ShrinkDatabaseWrapper
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

	declare @rc int;
    declare @msg varchar(255);
	declare @sql nvarchar(max);
	declare @schemaName varchar(200);
	declare @schemaInfo table (SchemaName varchar(200));
	declare @dbType table (DbType varchar(3));

	-- Physically attach the database
	set @msg = '';
	exec @rc = absp_Util_AttachDatabase
					@msg output,
					@dbName,
					@dbPath,
					@dbLogPath,
					@attachNoLog = 0;

	if (@rc = 0)
	begin

		set @sql = N'USE [' + @dbName + ']; select top 1 DbType from RQEVersion;';
		insert @dbType execute sp_executesql @sql;

		-- Only execute on EDB database
		if exists (select 1 from @dbType where DbType='EDB')
		begin
			-- truncate large Exposure tables
			set @sql = N'USE [' + @dbName + ']; if exists (select 1 from sys.tables where name=''ExposureValue'') truncate table ExposureValue;';
			print @sql;
			if (@shrinkFlag > 0) exec (@sql);
			set @sql = N'USE [' + @dbName + ']; if exists (select 1 from sys.tables where name=''ExposedLimitsByPolicy'') truncate table ExposedLimitsByPolicy;';
			print @sql;
			if (@shrinkFlag > 0) exec (@sql);
			set @sql = N'USE [' + @dbName + ']; if exists (select 1 from sys.tables where name=''ExposedLimitsByRegion'') truncate table ExposedLimitsByRegion;';
			print @sql;
			if (@shrinkFlag > 0) exec (@sql);
			set @sql = N'USE [' + @dbName + ']; if exists (select 1 from sys.tables where name=''ExposureReport'') truncate table ExposureReport;';
			print @sql;
			if (@shrinkFlag > 0) exec (@sql);
			set @sql = N'USE [' + @dbName + ']; if exists (select 1 from sys.tables where name=''ExposureReportInfo'') delete ExposureReportInfo;';
			print @sql;
			if (@shrinkFlag > 0) exec (@sql);


			-- drop exk schemas
			set @sql = N'USE [' + @dbName + ']; select name from sys.schemas where name like ''exk%'';';
			insert @schemaInfo execute sp_executesql @sql;

			declare curSchema cursor for select SchemaName from @schemaInfo;
			open curSchema;
			fetch curSchema into @schemaName;
			while @@fetch_Status=0
			begin
				set @sql = N'USE [' + @dbName + ']; exec absp_Util_CleanupSchema ''@schemaName'';';
				set @sql = replace(@sql, '@schemaName', @schemaName);
				print @sql;
				if (@shrinkFlag > 0) exec (@sql);
				fetch curSchema into @schemaName;
			end
			close curSchema;
			deallocate curSchema;
		end

		-- Shrink database
		exec absp_Util_AttachShrinkDetachDatabase @dbName, @dbPath, @dbLogPath, @shrinkFlag;

	end
	else
	begin
		print @msg;
	end

end

/*
exec absp_Util_ShrinkDatabaseWrapper
    @dbName='RQE13',
	@dbPath='D:\RQEDatabases\RQE13\RQE13 databases\EDB',
	@dbLogPath='D:\RQEDatabases\RQE13\RQE13 databases\EDB',
	@shrinkFlag=3;

exec absp_Util_ShrinkDatabaseWrapper
    @dbName='RQE13_IR',
	@dbPath='D:\RQEDatabases\RQE13\RQE13 databases\IDB',
	@dbLogPath='D:\RQEDatabases\RQE13\RQE13 databases\IDB'
	@shrinkFlag=2;
*/
