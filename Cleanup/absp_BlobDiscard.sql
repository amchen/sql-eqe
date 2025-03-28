if exists(select * from SYSOBJECTS where ID = object_id(N'absp_BlobDiscard') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_BlobDiscard;
end
go

create procedure absp_BlobDiscard
	@baseTableName varchar(120),
	@aportKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:

This procedure
- renames a table(baseTableName_aportKey) in the result database with a new name(baseTableName_aportKey_@@IDENTITY).
- drops the index for the table.
- updates the BLOBDROP table.

Returns:       Nothing.
=================================================================================
</pre>
</font>
##BD_END

##PD  @baseTableName     ^^ A string containing the base table name.
##PD  @aportKey          ^^ An integer value for the aportkey.
*/
as
begin

	set nocount on;

	declare @newKey int;
	declare @sql nvarchar(4000);
	declare @aportKeyStr varchar(30);
	declare @newTableName varchar(120);
	declare @tableName varchar(120);
	declare @sSql varchar(255);
	declare @execProcSql nvarchar(1000);
	declare @dbName varchar(255);

	set @aportKeyStr = cast(@aportKey as varchar(30));

	-- if on master side, call the remote side.
	-- this only happens in the SEQPLOUT cleanup case

	------------------- master side --------------------------------
	if(select top (1) DbType from RQEVersion) = 'EDB'
	begin
		select @dbName = DB_NAME() + '_IR';
		set @execProcSql ='exec [' + @dbName + ']..absp_BlobDiscard  ' + '''' + ltrim(rtrim(@baseTableName)) + '''' + ', ' + ltrim(rtrim(@aportKeyStr)) + '';
		exec (@execProcSql);
		return;
	end

	------------------- results side --------------------------------
	print GetDate();
	print ' Inside absp_BlobDiscard baseTableName = ' + @baseTableName;
	set @tableName = ltrim(rtrim(@baseTableName)) + '_' + ltrim(rtrim(@aportKeyStr));
	set @tableName = ltrim(rtrim(@tablename));

	-- if we have the table of interest
	if exists(select 1 from sysobjects with(nolock) where NAME = @tableName)
	begin
		begin try
			set @sql = 'drop table ' + @tableName;
			print @sql;
			execute(@sql);
		end try

		begin catch

		end catch
	end

	print GetDate();
	print ' Done absp_BlobDiscard';
end
