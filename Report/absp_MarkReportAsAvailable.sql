if exists(select * from SYSOBJECTS where ID = object_id(N'absp_MarkReportAsAvailable') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_MarkReportAsAvailable;
end
go

create procedure absp_MarkReportAsAvailable
	@engineCallID int,
	@nodeKey int,
	@nodeType int,
	@exposureKey int=0,
	@accountKey int=0,
	@anlCfgKey int=0

/*
====================================================================================================
DB Version:    	MSSQL
Purpose:		The procedure updates the Status column of AvailableReport table to 'Available'
				based on the given nodeKey and nodeType
Returns:		Nothing
====================================================================================================

@engineCallID  ^^ The flag for messaging purpose only.
@nodeKey  ^^ The nodeKey of the selected node.
@nodeType  ^^ The nodeType of the selected node.
@exposureKey  ^^ The exposure Key ( in case of Exposure and Analysis).
@accountKey  ^^ The account Key ( in case of Analysis).
@anlCfgKey  ^^ The anlCfg Key for which the status is to be updates.
*/
as
begin

	set nocount on;

	declare @sql varchar(max);
	declare @reportType int;
	declare @TableColumn varchar(100);
	declare @dt varchar(14);
	declare @retry int;

	set @retry = 10;

	exec absp_Util_GetDateString @dt  output,'yyyymmddhhnnss';

	set @reportType = 0;
	select top 1 @reportType=ReportTypeKey from ReportQuery where EngineCallID=@engineCallID;

	-- sanity check
	if (@reportType < 1 or @reportType > 7)
	begin
		execute absp_Migr_RaiseError 1,'absp_MarkReportAsAvailable: ReportType not found';
		return;
	end

	-- Convert nodeType
	if @nodeType =  3 set @nodeType = 23;
	if @nodeType =  7 set @nodeType = 27;
	if @nodeType = 10 set @nodeType = 30;

	select @TableColumn = Case @nodeType
		when 0  then 'FolderKey'
		when 1  then 'AportKey'
		when 2  then 'Pportkey'
		when 4  then 'AccountKey'
		when 8  then 'PolicyKey'
		when 9  then 'SiteKey'
		when 23 then 'RPortKey'
		when 27 then 'ProgramKey'
		when 30 then 'CaseKey'
		when 64 then 'ExposureKey'
		else ''
	end;

	-- sanity check
	if @TableColumn = ''
	begin
		exec absp_Migr_RaiseError 1,'absp_MarkReportAsAvailable: Invalid @nodeType parameter';
		return;
	end

	while (@retry > 0)
	begin
		begin try
			if @reportType = 1 --Exposure
			begin

				-- NOTE: The following @sql is used inside absp_GetExposureReportCount
				--       Do not change it unless you also change how it is used inside absp_GetExposureReportCount

				set @sql='select AnalysisRunKey from BatchJob where NodeType=@nodeType and @TableColumn=@nodeKey and Status = ''R'' and JobTypeID=22';
				set @sql=replace(@sql,'@nodeType',   cast(@nodeType as varchar(30)));
				set @sql=replace(@sql,'@TableColumn',@TableColumn);
				set @sql=replace(@sql,'@nodeKey',    cast(@nodeKey as varchar(30)));

				-- Update Exposure report counts
				exec absp_GetExposureReportCount @engineCallID, @nodeKey, @nodeType, @sql;

				--Update AvailableReport--
				set @sql='update AvailableReport set Status=''Available'' , CompletionDate=''' + @dt + ''' where AnalysisRunKey in ('+ @sql +
					') and ReportID in (select ReportID from ReportQuery where EngineCallId=' + cast(@engineCallID as varchar(30)) +')';

				begin transaction;
					exec (@sql);
				commit transaction;
			end
			else if (@reportType > 1 and @reportType < 7) --Analysis
			begin
				--Get the AnalysisRunKey for the given node based on nodeType--
				if @nodeType=4
					--Account
					set @sql='select AnalysisRunKey from AnalysisRunInfo where ExposureKey=@exposureKey and AccountKey=@accountKey';
				else if @nodeType=9
					--Site
					set @sql='select AnalysisRunKey from AnalysisRunInfo where ExposureKey=@exposureKey and AccountKey=@accountKey and SiteKey=@nodeKey';
				else
					set @sql='select AnalysisRunKey from BatchJob where NodeType=@nodeType and @TableColumn=@nodeKey and Status = ''R''';

				set @sql=replace(@sql,'@exposureKey',cast(@exposureKey as varchar(30)));
				set @sql=replace(@sql,'@accountKey', cast(@accountKey as varchar(30)));
				set @sql=replace(@sql,'@nodeType',   cast(@nodeType as varchar(30)));
				set @sql=replace(@sql,'@TableColumn',@TableColumn);
				set @sql=replace(@sql,'@nodeKey',    cast(@nodeKey as varchar(30)));

				--Update AvailableReport based on the given AnlCfgKey--
				set @sql='update AvailableReport set Status=''Available'', CompletionDate=''' + @dt + ''' where AnalysisRunKey in ('+ @sql +
					') and AnlCfgKey= ' + cast(@anlcfgKey as varchar) +
					' and ReportID in (select ReportID from ReportQuery where EngineCallId=' + cast(@engineCallID as varchar(30)) +')';

				begin transaction;
					exec (@sql);
				commit transaction;
			end
			else if @reportType = 7 --Import
			begin
				--Import reports do not have AnalysisRunKey so we must use ReportID for the given EngineCallID--
				--Update AvailableReport--
				begin transaction;
					update AvailableReport
						set Status='Available',CompletionDate= @dt
						where ExposureKey=@ExposureKey
							and ReportID in (select ReportID from ReportQuery where EngineCallId=@engineCallID);
				commit transaction;
			end
			else
			begin
				execute absp_Migr_RaiseError 1,'absp_MarkReportAsAvailable: ReportType not found';
			end

			set @retry = 0;

		end try

		begin catch
			if xact_state() <> 0
				rollback transaction;

			-- Retry if this is due to deadlock
			if (error_number() = 1205)
				set @retry = @retry - 1;
			else
				set @retry = -1;

			-- Exceeded retry, log the error
			if (@retry <= 0)
			begin
				declare @ProcName varchar(100);
				select @ProcName=object_name(@@procid);
				exec absp_Util_GetErrorInfo @ProcName;
			end
		end catch
	end -- while loop
end
