if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_SetDBVersion') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_SetDBVersion
end
GO

create procedure absp_Util_SetDBVersion
	@SchemaVersion varchar(25),
	@RQEVersion varchar(25),
	@FLCertificationVersion varchar(25),
	@theBUILD varchar(25),
	@PatchVersion varchar(5),
	@HotFixVersion varchar(5),
	@ScriptUsed varchar(254),
	@versionTbl varchar(120) = 'VERSION'
	

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will insert database version related information into a version table.

Returns: Nothing

====================================================================================================

</pre>
</font>
##BD_END


*/
as

begin

	set nocount on

	--------------------------------------------------------------------------------------
	-- This procedure inserts the supplied parameters into the RQEVERSION table.
	--------------------------------------------------------------------------------------
	declare @dbType varchar(3)
	declare @theDate varchar(25)
	declare @sql varchar(2000)
	declare @sql1 nvarchar(2000)
	declare @bExists int
	declare @createDt  char(14)
	declare @msg varchar(max)

	set @bExists = 0
	set @sql1 = 'select @bExists = count(*) from '+@versionTbl+' where BUILD = '''+@theBUILD+''''
	execute sp_executesql @sql1,N'@bExists int output',@bExists output

	if (@bExists = 0)
	begin

		exec absp_Util_GetDateString @theDate output, 'yyyymmdd'
		
		-- Build 5-1083xx format and later
		set @sql = 'insert into '+ltrim(rtrim(@versionTbl))+' (SchemaVersion,RQEVersion,FLCertificationVersion,Build,PatchVersion,VersionDate,HotfixVersion,ScriptUsed)'
		set @sql = @sql+' values ('''+  ltrim(rtrim(@SchemaVersion)) + ''',''' + ltrim(rtrim(@RQEVersion)) + ''',''' +
										  ltrim(rtrim(@FLCertificationVersion)) +''',''' + ltrim(rtrim(@theBUILD)) + ''',''' + ltrim(rtrim(@PatchVersion)) + ''','''+
										  ltrim(rtrim(@theDate)) + ''',''' + ltrim(rtrim(@HotfixVersion)) + ''',''' + ltrim(rtrim(@ScriptUsed)) + ''')'
		execute(@sql)
		set @msg = 'absp_Util_SetDBVersion: Successfully updated '+@versionTbl+' table to '+@theBUILD
		exec absp_Util_Log_Info @msg, 'absp_Util_SetDBVersion'
	end
	else
	begin
		set @msg = 'absp_Util_SetDBVersion: '+@theBUILD+' already exists in '+@versionTbl+' table'
		exec absp_Util_Log_Info @msg, 'absp_Util_SetDBVersion'
	end

    -- Populate DB_TYPE if it exists
    if exists (select 1 from INFORMATION_SCHEMA.COLUMNS where TABLE_NAME=@versionTbl and COLUMN_NAME='DbType')
    begin
        set @sql1 = 'select top 1 @dbType = DbType from ' + @versionTbl + ' order by VersionDate';
        execute sp_executesql @sql1, N'@dbType varchar(20) output', @dbType output
        set @sql = 'update ' + @versionTbl + ' set DbType = ''' + @dbType + '''';
        execute(@sql);
    end

end
