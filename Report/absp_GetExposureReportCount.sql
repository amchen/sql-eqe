if exists (select 1 from sysobjects where id = object_id(N'dbo.absp_GetExposureReportCount') and objectproperty(ID,N'IsProcedure') = 1)
begin
    drop procedure dbo.absp_GetExposureReportCount;
end
go

create procedure [dbo].[absp_GetExposureReportCount]
	@engineCallID int,
	@nodeKey int,
	@nodeType int,
	@sql varchar(max)
as

/*
====================================================================================================
Purpose:	This procedure updates the record count for the Exposure report
Returns:    Nothing
====================================================================================================

@engineCallID  ^^ The specific report engine call id.
@nodeKey  ^^ The nodeKey of the selected node.
@nodeType  ^^ The nodeType of the selected node.
*/

begin

	declare @mapTable table
		(ReportID int,
		 EngineCallID int,
		 NodeDescription varchar(30),
		 NodeType int,
		 ReportDisplayName varchar(256),
		 IsRegion int,
		 MainTableName varchar(100)
		);
	declare @ReportID int;
	declare @IsRegion int;
	declare @MainTableName varchar(100);
	declare @RecordCount int;
	declare @qry  nvarchar(max);
	declare @nqry nvarchar(max);
	declare @AnalysisRunKey int;

	insert @mapTable
		select ReportID, EngineCallID, NodeDescription,
			case NodeDescription
			when 'Accumulation Portfolio' then 1
			when 'Primary Portfolio'      then 2
			when 'Reinsurance Portfolio'  then 23
			else 27 end NodeType,
			ReportDisplayName,
			case when ReportDisplayName like '%Region'    then 1
				 when ReportDisplayName like '%Portfolio' then 2
				 when ReportDisplayName like '%Program'   then 2
				 else 0 end IsRegion,
			MainTableName
		from ReportQuery
			where EngineCallID = @engineCallID
			order by ReportQuery;

	set @qry = replace(@sql, 'select AnalysisRunKey', 'select @AnalysisRunKey=max(AnalysisRunKey)');
	execute sp_executesql @qry, N'@AnalysisRunKey int OUTPUT', @AnalysisRunKey=@AnalysisRunKey OUTPUT;

	declare cursMapTable cursor fast_forward for
		select ReportID, IsRegion, MainTableName from @mapTable where NodeType=@NodeType;

	open cursMapTable
	fetch next from cursMapTable into @ReportID, @IsRegion, @MainTableName;
	while @@fetch_status = 0
	begin

		set @nqry = N'select @RecordCount=count(*) from [@MainTableName] where NodeKey=@NodeKey and NodeType=@NodeType and EngineCallID=@EngineCallID';
		if (@MainTableName = 'ExposureSummaryReport') set @nqry = @nqry + N' and IsRegion=@IsRegion';

		set @nqry = replace(@nqry, '@MainTableName', @MainTableName);
		set @nqry = replace(@nqry, '@NodeKey', cast(@NodeKey as varchar(10)));
		set @nqry = replace(@nqry, '@NodeType', cast(@NodeType as varchar(10)));
		set @nqry = replace(@nqry, '@EngineCallID', cast(@EngineCallID as varchar(10)));
		set @nqry = replace(@nqry, '@IsRegion', cast(@IsRegion as varchar(10)));
		set @RecordCount=0;
		execute sp_executesql @nqry, N'@RecordCount int OUTPUT', @RecordCount=@RecordCount OUTPUT;

		begin transaction;
			update [AvailableReport] set RecordCount=@RecordCount where AnalysisRunKey=@AnalysisRunKey and ReportID=@ReportID;
		commit transaction;

		fetch next from cursMapTable into @ReportID, @IsRegion, @MainTableName;
	end
	close cursMapTable;
	deallocate cursMapTable;

end
