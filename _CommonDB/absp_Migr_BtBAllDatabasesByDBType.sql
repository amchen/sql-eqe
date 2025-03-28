if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_BtBAllDatabasesByDBType') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_BtBAllDatabasesByDBType;
end

go

create procedure absp_Migr_BtBAllDatabasesByDBType @dbType as varchar(3)
as
/*
====================================================================================================
Purpose:	This procedure marks all EDB/RDB depending on given DB type for build to build migration if required.
Returns:	Nothing
====================================================================================================
*/
begin
	set nocount on;

	declare @sql nvarchar(max);
	declare @dbName varchar(255);

	print GetDate()
	print ': absp_Migr_BtBAllDatabasesByDBType - Begin'

	if 1 = 1 --systemdb.dbo.absp_Util_IsBtBAvailable(@dbType) = 1
	begin
		print 'Available';
		--create TABLE TempResultTable (
		declare @TempResultTable TABLE (
			database_id int default 0,
			name varchar(120),
			physical_path varchar(1000) default '',
			size int default 0,
			growth int default 0,
			collation_name varchar(100) default '',
			dbType varchar(3),
			dbversion varchar(100) default '',
			build varchar(100) default ''
		);

		if (@dbType = 'RDB')
		begin
			insert into @TempResultTable exec absp_GetAttachedDatabases @dbType;
		end
		else
		begin
			insert into @TempResultTable(name, dbType) Select SDB.name, @dbType from sys.databases SDB
			inner join CFldrInfo cf on  SDB.name = cf.DB_NAME COLLATE DATABASE_DEFAULT inner join sys.master_files SMF on SDB.database_id = SMF.database_id
			Where SMF.file_id = 1;
		end

		DECLARE @isBtBRequired int;
		DECLARE DBcursor CURSOR fast_forward FOR select name from @TempResultTable;
		OPEN DBcursor;

		FETCH FROM DBcursor INTO @dbName;

		WHILE @@FETCH_STATUS = 0
		BEGIN
			exec commondb.dbo.absp_Migr_BtBDatabase @dbName, @dbType;

			FETCH FROM Dbcursor INTO @dbName;
		END
		CLOSE DBcursor;
		DEALLOCATE DBcursor;
	end

	-- end of the views cursor
	print GetDate()
	print ': absp_Migr_BtBAllDatabasesByDBType - End'
end
