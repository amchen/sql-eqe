if exists(select 1 FROM SYSOBJECTS WHERE id = object_id(N'absp_UpdateYLTAnalysisDbNames') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
	drop procedure absp_UpdateYLTAnalysisDbNames;
end
go

create procedure absp_UpdateYLTAnalysisDbNames @oldDbName varchar(120), @newDbName varchar(120)
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:   The procedure renames the associated AnalysisRuninfo's YLT database name when it is renamed 
		   from the UI treeview.
Returns:   Nothing
====================================================================================================
</pre>
</font>
##BD_END

##PD  @oldDbName ^^ The old database name
##PD  @newDbName ^^ The new database name
*/

begin
	set nocount on;
    declare @edbName varchar(120)
    declare @sql varchar(max);
       
    declare cursDbname cursor fast_forward for
		select DB_NAME from commondb.dbo.CFLDRINFO

	open cursDbname;
	fetch next from cursDbname into @edbName;
	while @@fetch_status = 0
	begin

		set @sql = 'update [@DBName].dbo.AnalysisRunInfo set YLTDatabaseName = ''@newRDBName'' where YLTDatabaseName = ''@RDBName''';
		set @sql = replace(@sql, '@DBName', @edbName);
		set @sql = replace(@sql, '@newRDBName', @newDbName);
		set @sql = replace(@sql, '@RDBName', @oldDbName);
		execute (@sql)

		fetch next from cursDbname into @edbName;
	end
	close cursDbname;
	deallocate cursDbname;
end