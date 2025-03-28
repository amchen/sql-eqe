if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_GetDBVersionCol') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Util_GetDBVersionCol
end
go

create procedure absp_Util_GetDBVersionCol
	@ret_BldVer varchar(max) output,
	@versionCol varchar(120),
	@versionTbl varchar(40) = 'RQEVersion',
	@noCommit int = 0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns the latest BUILD information from the VERSION table for a particular
Column of the Table in an OUT parameter.

Returns:       Nothing

====================================================================================================

</pre>
</font>
##BD_END

##PD  @ret_BldVer	^^ OUT parameter that holds the value of latest build and version.
##PD  @versionCol   ^^ A column of the Version maintaining table
##PD  @versionTbl 	^^ Name of Version maintaining table
##PD  @noCommit 	^^ Whether to Commit Work [0 to Commit]

*/
as
begin

   set nocount on

 --------------------------------------------------------------------------------------
  -- This procedure returns the latest BUILD information from the RQEVersion table.
  --------------------------------------------------------------------------------------
   declare @sql varchar(4000)
   declare @sql1 nvarchar(1024)
   declare @theCol varchar(255)

   if @versionTbl='Version' set @versionTbl='RQEVersion'

   --if @versionCol='WCEVERSION'
   --   	set @versionCol='RQEVersion'
  -- else if @versionCol=' FL_CERTVER'
   --	set @versionCol='FlCertificationVersion'

   create table #TMP_VERSION
	(
		DB_NAME    varchar(254) COLLATE SQL_Latin1_General_CP1_CI_AS,
		DB_SCHEMA  varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
		ARC_SCHEMA varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
		WCEVERSION varchar(8) COLLATE SQL_Latin1_General_CP1_CI_AS,
		EQEVERSION varchar(8) COLLATE SQL_Latin1_General_CP1_CI_AS,
		BUILD      varchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS,
		UPDATED_ON varchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS,
		SCRIPTUSED varchar(254) COLLATE SQL_Latin1_General_CP1_CI_AS,
		FL_CERTVER varchar(25)  COLLATE SQL_Latin1_General_CP1_CI_AS,
		DB_TYPE    varchar(25)  COLLATE SQL_Latin1_General_CP1_CI_AS
	)

   if exists(select  1 from SYS.SYSCOLUMNS as s where object_name(id) = @versionTbl and NAME = 'SchemaVersion')
   begin
	  set @sql = 'insert into #TMP_VERSION select top 1 case when DBType=''IDB'' then ''Results'' else ''Master'' end as DB_NAME,'
	  set @sql = @sql + ' dbo.trim(SchemaVersion) as DB_SCHEMA,'''' as ARC_SCHEMA,'
	  set @sql = @sql +' dbo.trim(RQEVersion) as WCEVERSION,'''' as EQEVERSION,'
   end

   set @sql = @sql+' dbo.trim(Build) as BUILD,VersionDate as UPDATED_ON,ScriptUsed as SCRIPTUSED,FlCertificationVersion as FL_CERTVER,DBType as DB_TYPE from ' + ltrim(rtrim(@versionTbl)) + ' order by BUILD desc, WCEVERSION desc'
   execute(@sql)

   set @sql1 = 'select @theCol = ' + ltrim(rtrim(@versionCol)) + ' from #TMP_VERSION'
   execute sp_executesql @sql1,N'@theCol VARCHAR(255) output',@theCol output

   set @ret_BldVer = @theCol
end
