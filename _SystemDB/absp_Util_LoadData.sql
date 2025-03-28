if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_LoadData') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_LoadData
end
go

create procedure absp_Util_LoadData
	@theTable     varchar(120),
	@theFilePath  varchar(255),
	@theDelimiter varchar(2) = ',',
	@theFirstRow  int = 1,
	@theFmtFile   varchar(255) = ''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    SQL2005
Purpose:

    This procedure loads a given table with data from a given file as specified
    in the FilePath parameter.

Returns:       Nothing
=================================================================================
</pre>
</font>
##BD_END
##PD  theTable       ^^ Name of the table which is to be populated.
##PD  theFilePath    ^^ The path of the data file which has the data.
##PD  theDelimiter   ^^ The delimiter used to separate the data.
*/
as
begin

   set nocount on

	-- This proc bulk loads into theTable from theFilePath using theDelimiter
	declare @filepath char(255)
	declare @sql varchar(max)
	declare @me varchar(1000)
	declare @pathExists int
    declare @tableExists int
    declare @msgTxt varchar(1000)
    declare @error int
    declare @useFmtFile varchar(300)

    set @me = 'absp_Util_LoadData'

	--Defect SDG__00018799 - Check errors while loading table--
    --Check if tablename is valid--
	exec @tableExists = absp_Util_CheckIfTableExists @theTable

	if  @tableExists = 0
	begin
	    set @msgTxt = @me + ': Table '+   ltrim(rtrim(@theTable))  + ' does not exist'
	    raiserror(@msgTxt,16,1)
	    return
	end

	--Check if path is valid--
	execute absp_Util_Replace_Slash @filepath output, @theFilePath

	exec @pathExists = absp_Util_getfileSizeMB  @filepath

	if  @pathExists < 0
	begin
		set @msgTxt = @me + ': Invalid Path ' + @filepath
		raiserror(@msgTxt,16,1)
		return
	end

	-- Are we using a format file
	if len(@theFmtFile) > 1
		set @useFmtFile = 'FORMATFILE=''@theFmtFile'',';
	else
		set @useFmtFile = '';

	set @sql = 'BULK INSERT ' + rtrim(@theTable) + ' FROM ''' + rtrim(@filepath) + '''' +
				   ' WITH (DATAFILETYPE=''char'',' +
						  'FIRSTROW=@theFirstRow,' +
				           @useFmtFile +
				          'CODEPAGE=1252,' +
						  'KEEPIDENTITY,' +
						  'ROWS_PER_BATCH=10000,' +
						  'FIELDTERMINATOR=''' + @theDelimiter + ''') '

	-- Replace @variables
	set @sql = replace(@sql, '@theFirstRow', cast(@theFirstRow as varchar))
	set @sql = replace(@sql, '@theFmtFile', @theFmtFile)

	begin try
		exec absp_Util_Log_Info @sql, @me
		execute(@sql)
		if (rtrim(upper(@theTable)) = 'QRYTABLE')
		begin
			set @msgTxt = 'Execute Post LoadData query for QRYTABLE'
			exec absp_Util_LogIt @msgTxt, 1, @me
			update QRYTABLE set QUERYTEXT = replace (dbo.trim(QUERYTEXT), '\x0A',' ')
			update QRYTABLE set QUERYTEXT = replace (dbo.trim(QUERYTEXT), '\x09',' ')
		end
	end try

	begin catch
		set @msgTxt = @me + ': Error Loading Table'
		raiserror(@msgTxt,16,1)
	end catch

end
