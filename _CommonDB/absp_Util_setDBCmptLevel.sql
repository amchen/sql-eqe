if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_setDBCmptLevel') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Util_setDBCmptLevel;
end
go

create procedure absp_Util_setDBCmptLevel @dbname varchar(130), @new_cmptlevel int = 0

/*
====================================================================================================
Purpose:

This procedure will set the given compatibility level to the given database. If the level is not specified then
it will set default level.

Returns:       Nothing
====================================================================================================

@dbname ^^  database name to change.
@new_cmptlevel ^^  the new compatibility level to change to.

*/
as
begin

	set nocount on;

	declare @serverVersion varchar(100);
	declare @ncmd nvarchar(1024);

	--Enclose within square brackets--
	execute absp_getDBName @dbname out, @dbname;

	if @new_cmptlevel = 0
	begin
		set @serverVersion = convert(VARCHAR(100),SERVERPROPERTY('PRODUCTVERSION'))
		set @serverVersion = LEFT(@serverVersion, CHARINDEX('.', @serverVersion, 1) - 1)
		set @serverVersion = @serverVersion + '0'
	end
	else
	begin
		set @serverVersion = convert(VARCHAR(10),@new_cmptlevel)
	end

	SET @ncmd = 'ALTER DATABASE ' + @dbname + ' SET COMPATIBILITY_LEVEL = ' + CONVERT(NVARCHAR(10), @serverVersion);
	print @ncmd;

	EXEC sp_executesql @ncmd;

end
