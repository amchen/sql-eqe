if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_Util_CleanupTempIDB') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Util_CleanupTempIDB;
end
go

create procedure absp_Util_CleanupTempIDB
	@dbName  varchar(120)

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure will get call when the task to create temporary IDB fails.
Returns:	Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @dbName  ^^ The name of the database that the task is suppose to create.

*/

as

begin
	set nocount on;

	declare @sql nvarchar(max);
	set @sql = replace(@sql, '@DatabaseName', @dbName);

	-- Reset the temporary IDB name in BatchJob
	set @sql = 'update commondb..BatchJob set TempIDBName = '''' where TempIDBName = ''' + @dbName + '''';
	print @sql;
	execute (@sql);

	-- Now drop the temp IDB
	exec absp_Util_DropDatabase @dbName;
end

