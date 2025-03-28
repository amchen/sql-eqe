if exists(select * from sysobjects where id = object_id(N'absp_getDatabaseNameForLock') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_getDatabaseNameForLock
end
 go
create procedure absp_getDatabaseNameForLock @databaseType varchar(10) = '', @curRefKey int = 0
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return the databaseName based on database type

Returns:      DatabaseName

====================================================================================================
</pre>
</font>
##BD_END

##PD  @databaseType    ^^  Database Type
##PD  @curRefKey   ^^  Currency Ref Key


*/

BEGIN
	SET NOCOUNT ON;

	declare @databaseName varchar(200);
	declare @dbName varchar(200);
	declare @database_id int;
	
	if @databaseType = 'EDB'	
	begin
		select @databaseName = DB_NAME from CFLDRINFO where Cf_Ref_Key = @curRefKey and DB_NAME IS NOT NULL;
		if	@databaseName IS NULL
		begin
			set @databaseName = ''
		end
		select @databaseName as databaseName;
		return;
	end
	
	else if @databaseType = 'RDB'
	
	begin
		--create Temporary table TempResultTable
		create table #TempResultTable (database_id int,name varchar(120),physical_path varchar(100), size int,growth int,collation_name varchar(100),dbType varchar(3),dbversion varchar(100),build varchar(100));
		
		-- Insert all the data returned from calling the procedure
		INSERT INTO #TempResultTable EXEC absp_GetAttachedDatabases 'RDB';
		
		declare  c1 cursor for select database_id, name from #TempResultTable;
		open c1;
		fetch c1 into @database_id, @dbName;
		while @@fetch_status=0
		begin
			if @curRefKey = @database_id
			begin
				select @dbName as databaseName;
				return;
			end
			fetch next from c1 into @database_id, @dbName;
		end
		
		close c1;
		deallocate c1;
	end

	-- If no match is found return empty resultset to satisfy hibernate
	select '' as databaseName
	return;
END
