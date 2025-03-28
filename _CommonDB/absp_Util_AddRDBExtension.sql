if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_AddRDBExtension') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_AddRDBExtension;
end
go

create procedure absp_Util_AddRDBExtension
(
	@extensionName varchar(120),
	@doit int=0
)

/*
=============================================================================================================
Purpose: This procedure renames all RDB databases by adding the extension to the logical and physical names.
Returns: None
Usage:
         exec absp_Util_AddRDBExtension '_RDB';      -- This will display what the procedure will do,
                                                     -- but not execute the rename.

         exec absp_Util_AddRDBExtension '_RDB', 1;   -- This will execute the rename.

=============================================================================================================
*/

as
begin
	declare @query varchar(2000);
	declare @sourceDBName varchar(255);
	declare @destDbName varchar(255);
	declare @sourceDb_mdf varchar(400);
	declare @sourceDb_ldf varchar(400);
	declare @destDb_mdf varchar(400);
	declare @destDb_ldf varchar(400);
	declare @isValid int;
	declare @nLen int;
	declare @msg varchar(max);
	declare @qry varchar(max);
	declare @nqry nvarchar(max);
	declare @extName varchar(120);

	if not exists (select 1 from RQEVersion where DBType='COM')
	begin
		print 'INFO: This procedure must be executed from the commondb database';
		return;
	end

	-- create dblist table
	create table #dblist (dbname varchar(120));

	-- get list of attached databases
	set @extensionName = ltrim(rtrim(@extensionName));
	set @extName = replace(@extensionName, '_', '[_]');

	set @qry = 'insert #dblist (dbname) select rtrim(name) from sys.databases where name not like ''%' + @extName + ''' and database_id > 4';
	execute(@qry);

	declare cursDBList cursor fast_forward for
		select dbname from #dblist;

	open cursDBList
	fetch next from cursDBList into @sourceDBName;
	while @@fetch_status=0
	begin
		set @isValid = 0;
		set @nqry = 'if exists (select 1 from [@dbname].sys.tables where name=''RQEVersion'') if exists (select 1 from [@dbname].dbo.RQEVersion where DbType=''RDB'') set @isValid=1';
		set @nqry = replace(@nqry, '@dbname', @sourceDBName);
		execute sp_executesql @nqry, N'@isValid int output', @isValid output;

		if (@isValid = 1)
		begin
			print '';

			set @msg = 'Renaming database [@dbname]...';
			set @msg = replace(@msg, '@dbname', @sourceDBName);
			print @msg;

			set @destDbName = @sourceDBName + @extensionName;
			if (len(@destDbName) < 121)
			begin
				set @msg = 'New database name [@destDbName]...';
				set @msg = replace(@msg, '@destDbName', @destDbName);
				print @msg;

				set @nqry = 'select @sourceDb_mdf=physical_name from [@dbname].sys.database_files where type=0';
				set @nqry = replace(@nqry, '@dbname', @sourceDBName);
				execute sp_executesql @nqry, N'@sourceDb_mdf varchar(400) output', @sourceDb_mdf output;

				set @nqry = 'select @sourceDb_ldf=physical_name from [@dbname].sys.database_files where type=1';
				set @nqry = replace(@nqry, '@dbname', @sourceDBName);
				execute sp_executesql @nqry, N'@sourceDb_ldf varchar(400) output', @sourceDb_ldf output;

				set @nLen = 1 + len(@sourceDBName + '.mdf');
				set @nLen = len(@sourceDb_mdf) - @nLen;
				set @destDb_mdf = left(@sourceDb_mdf, @nLen);

				set @nLen = 1 + len(@sourceDBName + '_log.ldf');
				set @nLen = len(@sourceDb_ldf) - @nLen;
				set @destDb_ldf = left(@sourceDb_ldf, @nLen);

				print @sourceDb_mdf;
				print @sourceDb_ldf;
				print @destDb_mdf;
				print @destDb_ldf;

				if (@doit <> 0)
				begin
					exec absp_Util_RenameRDB @sourceDBName, @destDbName, @destDb_mdf, @destDb_ldf;
/*
Renaming database [RDB_ac1]...
New database name [RDB_ac1_RDB]...
D:\RQEDatabases\SQL2008R2\UserDatabases\RDB\RDB_ac1.mdf
D:\RQEDatabases\SQL2008R2\UserDatabases\RDB\RDB_ac1_log.ldf

	absp_Util_RenameRDB
	(
	@sourceName varchar(254) = 'Base_CurrencyFolder',
	@destName varchar(254), -- the new CF database name
	@destLocation varchar(254) = 'C:\WceDB\Currency\PRI',
	@destLogLocation varchar(254) = 'C:\WceDB\Currency\PRI'
	)
*/
				end
				else
				begin
					set @msg = 'exec absp_Util_RenameRDB ''@sourceDBName'', ''@destDbName'', ''@destDb_mdf'', ''@destDb_ldf'';';
					set @msg = replace(@msg, '@sourceDBName', @sourceDBName);
					set @msg = replace(@msg, '@destDbName', @destDbName);
					set @msg = replace(@msg, '@destDb_mdf', @destDb_mdf);
					set @msg = replace(@msg, '@destDb_ldf', @destDb_ldf);
					print @msg;
				end

			end
			else
			begin
				set @msg = 'Cannot rename database to [@destDbName], the new name exceeds 120 characters.';
				set @msg = replace(@msg, '@destDbName', @destDbName);
				print @msg;
			end

		end
		else
		begin
			set @msg = 'Skipping database [@dbname], not a valid RQE or RDB database.';
			set @msg = replace(@msg, '@dbname', @sourceDBName);
			print @msg;
		end

		fetch next from cursDBList into @sourceDBName;
	end

	close cursDBList;
	deallocate cursDBList;

end

-- exec absp_Util_AddRDBExtension '_RDB';
