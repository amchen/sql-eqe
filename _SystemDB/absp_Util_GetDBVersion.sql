if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_GetDBVersion') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetDBVersion
end
go

create procedure absp_Util_GetDBVersion
	@versionTbl varchar(100) = 'RQEVersion'
as

/*

##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version: MS SQL Server
Purpose:    This Procedure Informs about latest BUILD information of database from the RQEVERSION table.
====================================================================================================

</pre>
</font>
##BD_END

##PD   @versionTbl	^^ 	Name of table that maintains version as input parameter

##RS	DB_NAME		^^ 	The name of  the Database.  Valid names are:  "Master" or "Results".
##RS	DB_SCHEMA	^^	Database schema version.  This value must be incremented whenever DICTTBL, DICTCOL, or DICTIDX is changed.
##RS	ARC_SCHEMA	^^	Archive Database schema version.  This value must be incremented whenever ARCORDER, or the schema of a table referenced in ARCORDER is changed.
##RS	WCEVERSION	^^	The release version of the WCe Application.  Updated with every new release.
##RS	EQEVERSION	^^	The release version of the EQE Application.  Updated with every new release.
##RS	BUILD		^^	1st build for current database.  This is changed when database changes.
##RS	UPDATED_ON	^^	The date the VERSION table was updated by either an unload or load database migration script.
##RS	SCRIPTUSED	^^	The name of the database migration script used to perform either the database unload or load.
##RS	FL_CERTVER	^^	Specified whether this version is certified by the FHC.

*/
begin

	set nocount on;

	--------------------------------------------------------------------------------------
	-- This procedure returns the latest BUILD information from the VERSION table.
	-- The recordset format is:
	-- DB_NAME,DB_SCHEMA,ARC_SCHEMA,WCEVERSION,EQEVERSION,BUILD,UPDATED_ON,SCRIPTUSED
	--------------------------------------------------------------------------------------

	if @versionTbl='Version' set @versionTbl='RQEVersion';

	declare @sql varchar(max);

	if (select max(RQEVersion) from RQEVersion) < '15.00.02'
	begin
		set @sql = 'drop view BatchJob';
		execute(@sql);
		set @sql = 'create view BatchJob as select * from commondb..BatchJob';
		execute(@sql);
	end

	set @sql = 'select top 1 case when DBType=''IDB'' then ''Results'' else ''Master'' end as DB_NAME, dbo.trim(SchemaVersion) as DB_SCHEMA, '''' as ARC_SCHEMA, dbo.trim(RQEVersion)+''.''+substring(Build,15,3) as WCEVERSION,
				'''' as EQEVERSION, rtrim(ltrim(SUBSTRING(BUILD,5,LEN(BUILD) -4))) as BUILD, dbo.trim(VersionDate) as UPDATED_ON, ScriptUsed as SCRIPTUSED,
				dbo.trim(FlCertificationVersion) as FL_CERTVER  from ' + @versionTbl + ' order by BUILD desc, WCEVERSION desc; '

	execute(@sql);
end
