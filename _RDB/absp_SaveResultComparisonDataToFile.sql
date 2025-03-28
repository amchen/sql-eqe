if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_SaveResultComparisonDataToFile') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_SaveResultComparisonDataToFile;
end
go

create procedure absp_SaveResultComparisonDataToFile @sessionId int,
													 @header varchar(max),
													 @columnList varchar(max),
													 @whereClause varchar(8000),
													 @orderbyClause varchar(8000),
													 @outputPath varchar(255)
/*
====================================================================================================
Purpose:

	The procedure will save the Comarison results data to a text file including the headers.

Returns:	None
====================================================================================================
*/
as
begin try
	set nocount on;

	declare @resultsComparisonTable varchar(100);
	declare @tmpFile varchar(255);
	declare @outFile varchar(255);
	declare @sql varchar(8000);
	declare @dbName varchar(120);
	declare @xp_cmdshell_enabled int;

	exec @xp_cmdshell_enabled = absp_Util_IsUseXPCmdShell;

	set @dbName = DB_NAME();
	set @resultsComparisonTable='FinalResultsComparisonTbl_'+dbo.trim(cast(@sessionId as varchar(30)));

	if not exists(select 1 from sys.tables where name=@resultsComparisonTable)
		exec('drop table ' + @resultsComparisonTable);

	----------Get the Header info--------------
	set @outFile=@outputPath + '\ResultComparison_Data.txt';
	set @header=replace(@header,',',char(9));
	set @header=replace(@header,'>','^>'); -- escape dos redirection symbol
	set @tmpFile=@outputPath + '\Tmp_ResultComparison_Data.txt';

	----------Unload Header---------------
	if (@xp_cmdshell_enabled = 1)
	begin
		set @sql='echo ' + @header + ' > ' + @outFile;
		exec xp_cmdshell @sql, no_output;
	end
	else
	begin
		-- execute the command via CLR
		exec systemdb.dbo.clr_Util_WriteLine @outFile,@header,0;
	end

	-----------Write to Txt file---------------
	--Get columnNames except RowNum--
	set @sql=''
	set @sql='select ' + @columnList + ' from [' + @dbName + ']..' + @resultsComparisonTable;

	if len(@whereClause)>0
	begin
		-- replace whereClause 'XXX%' with 'All Countries%' because FinalResultsComparisonTbl stores COUNTRY_ID_A='All Countries'
		set @whereClause = REPLACE(@whereClause,'XXX%','All Countries%');
		set @sql=@sql + ' where ' + @whereClause;
	end

	if len(@orderByClause)>0 set @sql=@sql + ' order by ' + @orderByClause;
	print @sql;
	exec absp_Util_UnloadData 'Q',@sql,@tmpFile,'\t';

	--Concatenate Header and Data--
	if (@xp_cmdshell_enabled = 1)
	begin
		set @sql='type ' + @tmpFile + ' >> ' + @outFile;
		exec xp_cmdshell @sql, no_output;
	end
	else
	begin
		-- execute the command via CLR
		declare @rc int;
		exec @rc = systemdb.dbo.clr_Util_FileConcat @tmpFile, @outFile;
	end
	--Delete temp file--
	exec absp_Util_DeleteFile @tmpFile;

end try

begin catch
	declare @ProcName varchar(100),
			@msg as varchar(1000),
			@module as varchar(100),
			@ErrorSeverity varchar(100),
			@ErrorState int,
			@ErrorMsg varchar(4000);

	select @ProcName = object_name(@@procid);
    	select	@module = isnull(ERROR_PROCEDURE(),@ProcName),
        @msg='"'+ERROR_MESSAGE()+'"'+
        		'  Line: '+cast(ERROR_LINE() as varchar(10))+
				'  No: '+cast(ERROR_NUMBER() as varchar(10))+
				'  Severity: '+cast(ERROR_SEVERITY() as varchar(10))+
        		'  State: '+cast(ERROR_STATE() as varchar(10)),
        @ErrorSeverity=ERROR_SEVERITY(),
        @ErrorState=ERROR_STATE(),
        @ErrorMsg='Exception: Top Level '+@ProcName+'. Occurred in '+@module+'. Error: '+@msg;
	raiserror (
		@ErrorMsg,	-- Message text
		@ErrorSeverity,	-- Severity
		@ErrorState		-- State
	)
	return 99;
end catch
