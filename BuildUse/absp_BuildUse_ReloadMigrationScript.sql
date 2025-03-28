if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_BuildUse_ReloadMigrationScript') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_BuildUse_ReloadMigrationScript;
end
go

create procedure absp_BuildUse_ReloadMigrationScript
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure is to be used only for development purpose.
			The procedure deletes MigrationScript table and populates it from
			MigrationScript.xlsx file.
====================================================================================================
</pre>
</font>
##BD_END

*/
AS
begin

	set nocount on;
/*
	truncate table systemdb.dbo.MigrationScript;

	insert systemdb.dbo.MigrationScript
		select * from openrowset('Microsoft.ACE.OLEDB.12.0',
								 'Excel 12.0;Database=D:\Projects\Data_Files\CD-Db\EDM\System\MigrationScript.xlsx;HDR=YES',
								 'SELECT * FROM [Data$]');
	-- quick fix data as needed
	update systemdb.dbo.MigrationScript
		set IsCritical='' where IsCritical <> 'Y' or IsCritical is NULL;
	update systemdb.dbo.MigrationScript
		set IsDisabled='' where IsDisabled <> 'Y' or IsDisabled is NULL;
	update systemdb.dbo.MigrationScript
		set IsExternal='' where IsExternal <> 'Y' or IsExternal is NULL;
	update systemdb.dbo.MigrationScript
		set TableName='' where TableName is NULL;
	update systemdb.dbo.MigrationScript
		set ScriptText='' where ScriptText is NULL;
	update systemdb.dbo.MigrationScript
		set HotfixVersion='' where HotfixVersion is NULL;
*/
	select * from systemdb.dbo.MigrationScript
		order by RQEVersion, SeqNum;

end
