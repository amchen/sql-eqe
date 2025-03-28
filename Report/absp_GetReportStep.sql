if exists (select 1 from sysobjects where id = object_id(N'dbo.absp_GetReportStep') and objectproperty(ID,N'IsProcedure') = 1)
begin
    drop procedure dbo.absp_GetReportStep;
end
go

create procedure dbo.absp_GetReportStep
    @NodeKey      integer,
    @NodeType     integer,
    @EngineCallID integer,
    @IsBaseReport integer = 0,
    @JobKey       integer = 0
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:    This procedure returns the report steps for the given EngineCallID.
Returns:    Returns report steps ordered by ReportStepSequence.
Example:    exec absp_GetReportStep 1, 8, 50
====================================================================================================
</pre>
</font>
##BD_END

##PD  @NodeKey   ^^  The node type for the requested report.
##PD  @NodeType  ^^  The node key for the requested report.
##PD  @ReportID  ^^  The engine call ID or report id.
*/

BEGIN TRY

    declare @dtime                varchar(14);
    declare @expoKey              int;
    declare @expoReportKey        int;
    declare @nKey                 int;
    declare @nType                int;
    declare @StepTableName        varchar(100);
    declare @qry                  varchar(max);
    declare @qry2                 varchar(max);
    declare @qry3                 varchar(max);
    declare @ReportStepCommand    varchar(50);
    declare @ReportStepValue      varchar(5999);
    declare @ReportStepReturnType varchar(50);
    declare @steps          table (ReportStepSequence   integer identity(1,1),
                                   ReportStepCommand    varchar(50),
                                   ReportStepValue      varchar(5999),
                                   ReportStepReturnType varchar(50));

	-- Check parameters
	if (@NodeKey < 1)
	begin
		exec absp_Migr_RaiseError 1, 'absp_GetReportStep: Invalid NodeKey';
		return;
	end
	if (@NodeType < 1)
	begin
		exec absp_Migr_RaiseError 1, 'absp_GetReportStep: Invalid NodeType';
		return;
	end

	-- Convert Program to Account NodeType
	if (@NodeType = 7) set @NodeType = 27;

	-- Filter EngineCallID
	if (@EngineCallID < 40 or @EngineCallID > 56)
	begin
		exec absp_Migr_RaiseError 1, 'absp_GetReportStep: Invalid EngineCallID';
		return;
	end

    -- Validate the EngineCallID
    if exists (select 1 from ReportQuery where EngineCallID = @EngineCallID)
    begin

		exec absp_Util_GetDateString @dtime output;

		-- Get the StepTable for this report
		select top 1 @StepTableName=StepTable from ReportQuery where EngineCallID = @EngineCallID;

		-- Report step cursor
		set @qry = 'declare cursStepTable cursor global for ' +
						'select Command, Value, ReturnType ' +
						'from @StepTableName ' +
						'where Rem in ('''', NULL) and ReportID=@EngineCallID ' +
						'order by Step asc';
		set @qry = replace(@qry, '@StepTableName', @StepTableName);
		set @qry = replace(@qry, '@EngineCallID', cast(@EngineCallID as varchar(30)));

		-- Init variables
		set @expoKey = -1;

		-- Get the latest ExposureKey created
		select top 1 @expoKey=m.ExposureKey
			from ExposureMap m inner join ExposureInfo i on m.ExposureKey = i.ExposureKey
			where (i.ImportStatus='Completed' or i.ImportStatus='Failed') and m.ParentKey=@NodeKey and m.ParentType=@NodeType
			order by m.ExposureKey desc;

		---------------------------------------------------------------
		-- Import Report
		---------------------------------------------------------------
    	if (@EngineCallID < 50)
		begin
			set @qry2 = 'update ImportReportInfo set Status=''Active'' where ExposureKey=@expoKey and ReportID=@EngineCallID;';
			set @qry2 = replace(@qry2, '@EngineCallID', cast(@EngineCallID as varchar(30)));

			-- Validate the ExposureKey
			if not exists (select 1 from ImportReportInfo where ExposureKey=@expoKey and ReportID=@EngineCallID and Status in ('Active','New'))
			begin
				insert into ImportReportInfo (ExposureKey,ReportID,Status,ModifyDate) values (@expoKey,@EngineCallID,'New',@dtime);
				execute(@qry);
				open cursStepTable;
				fetch next from cursStepTable into @ReportStepCommand, @ReportStepValue, @ReportStepReturnType;
				while @@fetch_status=0
				begin
					set @ReportStepValue = replace(@ReportStepValue, '@EngineCallID',  @EngineCallID);
					set @ReportStepValue = replace(@ReportStepValue, '@expoKey',  @expoKey);
					set @ReportStepValue = replace(@ReportStepValue, '@NodeKey',  @NodeKey);
					set @ReportStepValue = replace(@ReportStepValue, '@NodeType', @NodeType);
					set @ReportStepValue = replace(@ReportStepValue, '@JobKey',   @JobKey);
					insert into @steps (ReportStepCommand, ReportStepValue, ReportStepReturnType) values (@ReportStepCommand, @ReportStepValue, @ReportStepReturnType);
					fetch next from cursStepTable into @ReportStepCommand, @ReportStepValue, @ReportStepReturnType;
				end
				close cursStepTable
				deallocate cursStepTable

				-- Set ExposureReportInfo.Status='Active'
				if (@expoKey > 0)
				begin
					set @qry3 = replace(@qry2, '@expoKey', cast(@expoKey as varchar(30)));
					insert into @steps (ReportStepCommand, ReportStepValue, ReportStepReturnType) values ('SQL', @qry3, '');
				end
			end
		end
		else if (@IsBaseReport = 1)
		---------------------------------------------------------------
		-- Exposure Base Report
		---------------------------------------------------------------
    	begin

    		exec absp_Util_CreateExposureViewsToIDB @JobKey;

			-- Init variables
			set @expoKey=0;
			set @expoReportKey=0;

			-- Report step cursor
			set @qry = 'declare cursStepTable cursor global for ' +
							'select Command, Value, ReturnType ' +
							'from @StepTableName ' +
							'where Rem in ('''', NULL) and ReportID=@EngineCallID ' +
							'order by Step asc';
			set @qry = replace(@qry, '@StepTableName', @StepTableName);
			set @qry = replace(@qry, '@EngineCallID', '10');

			set @qry2 = 'update ExposureReportInfo set Status=''Active'' where ExposureReportKey=@expoReportKey;';

			-- get all child nodes
			create table #NODELIST (NODE_KEY INT, NODE_TYPE INT, PARENT_KEY INT, PARENT_TYPE INT);
			execute absp_PopulateChildList @NodeKey, @NodeType;

			-- insert the current node
			insert #NODELIST (NODE_KEY,NODE_TYPE,PARENT_KEY,PARENT_TYPE) values (@NodeKey,@NodeType,@NodeKey,@NodeType);

			-- clean up non-Exposure nodes
			delete from #NODELIST where NODE_TYPE not in(2,7,27);

			declare cursExpoBaseKey cursor fast_forward for
				select distinct e.ExposureKey,ParentKey,ParentType
					from ExposureMap e inner join #NODELIST n on e.ParentKey=n.Node_Key and e.ParentType=n.Node_Type
									   inner join ExposureInfo i on e.ExposureKey = i.ExposureKey and i.Status='Imported';

			open cursExpoBaseKey
			fetch next from cursExpoBaseKey into @expoKey,@nKey,@nType
			while @@fetch_status=0
			begin
				-- Validate the ExposureKey
				if not exists (select 1 from ExposureReportInfo where ExposureKey=@expoKey and ParentKey=@nKey and ParentType=@nType and Status in ('Active','New'))
				begin
					insert into ExposureReportInfo (ExposureKey,ParentKey,ParentType,Status,ModifyDate) values (@expoKey,@nKey,@nType,'New',@dtime);
					set @expoReportKey=@@identity;
					execute(@qry);
					open cursStepTable;
					fetch next from cursStepTable into @ReportStepCommand, @ReportStepValue, @ReportStepReturnType;
					while @@fetch_status=0
					begin
						set @ReportStepValue = replace(@ReportStepValue, '@EngineCallID',  @EngineCallID);
						set @ReportStepValue = replace(@ReportStepValue, '@expoReportKey', @expoReportKey);
						set @ReportStepValue = replace(@ReportStepValue, '@expoKey',       @expoKey);
						set @ReportStepValue = replace(@ReportStepValue, '@NodeKey',       @nKey);
						set @ReportStepValue = replace(@ReportStepValue, '@NodeType',      @nType);
						set @ReportStepValue = replace(@ReportStepValue, '@JobKey',        @JobKey);
						insert into @steps (ReportStepCommand, ReportStepValue, ReportStepReturnType) values (@ReportStepCommand, @ReportStepValue, @ReportStepReturnType);
						fetch next from cursStepTable into @ReportStepCommand, @ReportStepValue, @ReportStepReturnType;
					end
					close cursStepTable
					deallocate cursStepTable

					-- Set ExposureReportInfo.Status='Active'
					if (@expoKey > 0)
					begin
						set @qry3 = replace(@qry2, '@expoReportKey', cast(@expoReportKey as varchar(30)));
						insert into @steps (ReportStepCommand, ReportStepValue, ReportStepReturnType) values ('SQL', @qry3, '');
					end
				end

				fetch next from cursExpoBaseKey into @expoKey,@nKey,@nType
			end
			close cursExpoBaseKey
			deallocate cursExpoBaseKey
		end
		---------------------------------------------------------------
		-- Exposed Limits Report
		---------------------------------------------------------------
		else if (@EngineCallID = 54 or @EngineCallID = 55 or @EngineCallID = 56)
		begin
			-- Validate the Report
			if not exists (select 1 from ExposedLimitsReport where NodeKey=@NodeKey and NodeType=@NodeType and EngineCallID=@EngineCallID)
			begin
				execute(@qry);
				open cursStepTable;
				fetch next from cursStepTable into @ReportStepCommand, @ReportStepValue, @ReportStepReturnType;
				while @@fetch_status=0
				begin
					set @ReportStepValue = replace(@ReportStepValue, '@EngineCallID', @EngineCallID);
					set @ReportStepValue = replace(@ReportStepValue, '@expoKey',  @expoKey);
					set @ReportStepValue = replace(@ReportStepValue, '@NodeKey',  @NodeKey);
					set @ReportStepValue = replace(@ReportStepValue, '@NodeType', @NodeType);
					set @ReportStepValue = replace(@ReportStepValue, '@JobKey',   @JobKey);
					insert into @steps (ReportStepCommand, ReportStepValue, ReportStepReturnType) values (@ReportStepCommand, @ReportStepValue, @ReportStepReturnType);
					fetch next from cursStepTable into @ReportStepCommand, @ReportStepValue, @ReportStepReturnType;
				end
				close cursStepTable
				deallocate cursStepTable
			end
		end
		else
		---------------------------------------------------------------
		-- All other Exposure Reports
		---------------------------------------------------------------
    	begin
			-- Validate the Report
			if not exists (select 1 from ExposureSummaryReport where NodeKey=@NodeKey and NodeType=@NodeType and EngineCallID=@EngineCallID)
			begin
				execute(@qry);
				open cursStepTable;
				fetch next from cursStepTable into @ReportStepCommand, @ReportStepValue, @ReportStepReturnType;
				while @@fetch_status=0
				begin
					set @ReportStepValue = replace(@ReportStepValue, '@EngineCallID', @EngineCallID);
					set @ReportStepValue = replace(@ReportStepValue, '@expoKey',  @expoKey);
					set @ReportStepValue = replace(@ReportStepValue, '@NodeKey',  @NodeKey);
					set @ReportStepValue = replace(@ReportStepValue, '@NodeType', @NodeType);
					set @ReportStepValue = replace(@ReportStepValue, '@JobKey',   @JobKey);
					insert into @steps (ReportStepCommand, ReportStepValue, ReportStepReturnType) values (@ReportStepCommand, @ReportStepValue, @ReportStepReturnType);
					fetch next from cursStepTable into @ReportStepCommand, @ReportStepValue, @ReportStepReturnType;
				end
				close cursStepTable
				deallocate cursStepTable
			end
		end
    end

    select ReportStepSequence, ReportStepCommand, ReportStepValue, ReportStepReturnType from @steps order by ReportStepSequence asc;

END TRY

BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH

/*
exec absp_GetReportStep 1, 2, 50
select Command, Value, ReturnType from ReportStepExposure where Rem in ('', NULL) order by Step asc
*/
