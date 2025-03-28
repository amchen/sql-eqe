if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_MakeDatabaseOnlineOffline') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_MakeDatabaseOnlineOffline
end

go
create procedure absp_Util_MakeDatabaseOnlineOffline @dbName varchar(130), @dbtype varchar(5), @isOnline int = 0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure will make the given database online or offline depending on the given choice
Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

*/
AS
begin
	set nocount on;

	declare @sql nvarchar(max);
	declare @key int
	declare @IRDBName varchar(135)

	set @dbName = ltrim(rtrim(@dbName));

	-- strip brackets
	set @dbName = replace(@dbName,'[','');
	set @dbName = replace(@dbName,']','');
	set @IRDBName = dbo.trim(@dbName) + '_IR'

	print @dbName;
	print @dbtype;

	if @dbtype = 'EDB'
	begin
		select @key = CF_REF_KEY from CFLDRINFO where DB_NAME = @dbName
	end
	else if @dbtype = 'RDB'
	begin
		set @sql = N'SELECT @key = rdbInfoKey FROM [' + @dbName + '].dbo.rdbinfo where nodeType = 101 and longname = ''' +@dbName + '''';
		print @sql;
		execute sp_executesql @sql, N'@key int OUTPUT', @key=@key OUTPUT;
	end
	print @key;

	if @isOnline = 1
	begin
		
		exec absp_InfoTableAttribSetOfflineMode  @key, 0, @dbName
		if @dbtype = 'EDB'
		begin
			exec absp_InfoTableAttribSetCurrencyNodeAvailable  @key,1
		end
	end
	else if @isOnline = 0
	begin
		exec absp_InfoTableAttribSetOfflineMode  @key, 1, @dbName
		if @dbtype = 'EDB'
		begin
			exec absp_InfoTableAttribSetCurrencyNodeAvailable  @key,0
			print @dbtype
		end
	end
end
