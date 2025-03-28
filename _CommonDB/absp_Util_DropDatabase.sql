if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_Util_DropDatabase') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Util_DropDatabase;
end
go

create procedure absp_Util_DropDatabase
	@dbName  varchar(120)
	
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure will drop an\ \ database. 
Returns:	Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @mdfPath ^^ The path to where to create the MDF file
##PD  @ldfPath ^^ The path to where to create the LDF file
##PD  @dbName  ^^ The name you want the databae to have

*/

as

begin
	set nocount on;

	declare @sql nvarchar(max);		-- statements we execute
	set @sql = replace(@sql, '@DatabaseName', @dbName);
	-- Now detach the Database from SQL Server.
	if exists ( select 1 from sys.databases where name = @dbName )
	begin
		set @sql = 'USE [' + @dbName + '] ';
		set @sql = @sql + 'ALTER DATABASE [' + @dbName + '] set SINGLE_USER WITH ROLLBACK IMMEDIATE ';
		print @sql;
		execute (@sql);
		set @sql = 'USE [master]; DROP DATABASE [' + @dbName + '] ';
		print @sql;
		execute (@sql);
		print 'done';

	
	end
end

