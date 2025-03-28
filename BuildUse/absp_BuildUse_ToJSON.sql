if exists(select * from SYSOBJECTS where ID = object_id(N'absp_BuildUse_ToJSON') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_BuildUse_ToJSON;
end
go

create procedure absp_BuildUse_ToJSON
	@tableName varchar(200),
	@unloadJSON int = 0,
	@fileFolder varchar(255) = 'C:\\Temp'
as

begin

	SET NOCOUNT ON;

	declare @checkLogPath varchar(255);
	declare @filePath     varchar(255);
	declare @me           varchar(255);
	declare @msg          varchar(max);
	declare @sql          varchar(max);
	declare @str          varchar(max);
	declare @str2         varchar(8000)
	declare @qry          varchar(max);

	set @me = 'absp_BuildUse_ToJSON';
	set @msg = 'Starting...';
	exec absp_Util_Log_Info @msg, @me ;

	if exists (select 1 from sysobjects where name = 'tmp_ToJSON')
		drop table tmp_ToJSON;

	create table tmp_ToJSON (JSONstring varchar(max));

	set @qry = 'insert tmp_ToJSON select dbo.FlattenedJSON( (select * from [@tableName] for XML path,root) )';
	set @qry = replace(@qry, '@tableName', @tableName);
	execute(@qry);

	-- unload to file
	if (@unloadJSON = 1)
	begin
		set @filePath = @fileFolder + '\\' + @tableName + '.json';
		exec absp_Util_UnloadData @unloadType='Q', @unloadText='select JSONstring from tmp_ToJSON', @outFile=@filePath, @delimiter='\t';
	end
	else
	begin
		select JSONstring from tmp_ToJSON;
	end

	if exists (select 1 from sysobjects where name = 'tmp_ToJSON')
		drop table tmp_ToJSON;

	set @msg = 'Completed.';
	exec absp_Util_Log_Info @msg, @me;
end

/*
exec absp_BuildUse_ToJSON
	@tableName = 'RQEVersion',
	@unloadJSON = 1,
	@fileFolder = 'C:\\Temp';
*/
