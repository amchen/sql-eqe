if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_Util_ExternalDB_GetMigrationScript') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Util_ExternalDB_GetMigrationScript;
end
go

create procedure absp_Util_ExternalDB_GetMigrationScript
	@scriptFileName varchar(255)

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure is used by external database management to generate the migration script for EDB and RDB.
Returns:	Nothing.

Example:	exec absp_Util_ExternalDB_GetMigrationScript 'D:\RQEDatabases\MigrationScript\RQE14_MigrationScript.sql';

Notes:
1.	The path must be valid. The procedure will not validate or create the output path.
2.	If the output file already exists, it will be overwritten.
3.	The generated script has try-catch as well as transaction rollback if there are any errors encountered during migration.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @batchJobKey ^^ The batchJobKey
##PD  @debug ^^ The debug flag
*/

as

begin
	set nocount on;

	declare @minRQEVersion varchar(25);

	select @minRQEVersion = '13.00.00';
	exec absp_Migr_GenerateMigrationScript @scriptFileName, @minRQEVersion;
end
