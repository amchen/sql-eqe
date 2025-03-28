if exists (select * from sys.objects where object_id = object_id(N'dbo.absp_ImportErrorReport') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
begin
	drop function dbo.absp_ImportErrorReport;
end
go

create function dbo.absp_ImportErrorReport
(
	@ExposureKey int
)
returns @ErrorReport table
(
	MessageLevelName	varchar(120),
	MessageCode			varchar(50),
	SourceCategory		varchar(255),
	UserRowNumber		int,
	AccountNumber		varchar(50),
	PolicyNumber		varchar(50),
	SiteNumber			varchar(50),
	UserColumnName		varchar(100),
	UserValue			varchar(120),
	MessageText			varchar(5999)
)
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:    This function returns the Import Error report.
Example:    select * from dbo.absp_ImportErrorReport(1)
====================================================================================================
</pre>
</font>
##BD_END

##PD  @ExposureKey  ^^  Exposure key.
*/

begin
	if exists (select 1 from ImportErrorWarning where ExposureKey=@ExposureKey)
	begin
		insert @ErrorReport (MessageLevelName, MessageCode, SourceCategory, UserRowNumber, AccountNumber, PolicyNumber, SiteNumber, UserColumnName, UserValue, MessageText)
			select top 20000
				case MessageLevel when 1 then 'Error' when 2 then 'Warning' when 3 then 'Non-critical Warning' when 4 then 'Information' else 'Unknown MessageLevel' end,
				MessageCode,
				cast(SourceID as varchar(3)),
				--case f.SourceCategory when '' then 'All Data' else f.SourceCategory end,
				UserRowNumber,
				AccountNumber,
				PolicyNumber,
				SiteNumber,
				UserColumnName,
				UserValue,
				MessageText
			from ImportErrorWarning
			where ExposureKey=@ExposureKey
			  and SummaryCount=0
			order by MessageLevel, SourceID, UserRowNumber, UserColumnNumber;
	end
	else
	begin
		insert @ErrorReport values ('No Import Errors','','',NULL,'','','','','','');
	end
	return;
end
-- select * from dbo.absp_ImportErrorReport(2) order by MessageCode, SourceID, UserRowNumber, UserColumnName;
