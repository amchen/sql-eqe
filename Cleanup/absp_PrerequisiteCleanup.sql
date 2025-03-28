if exists(select * from SYSOBJECTS where ID = object_id(N'absp_PrerequisiteCleanup') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_PrerequisiteCleanup;
end
go

create procedure absp_PrerequisiteCleanup
	@nodeKey int,
	@nodeType int,
	@prerequisiteID int,
	@cleanupMode int
as
/*
====================================================================================================
Purpose:	This procedure cleans up database after the Prerequisite job.
Parameter:
	NodeKey:  The key of the node
	NodeType: The type of node (e.g. will be 64 for Exposure)
	PrerequisiteID:
		2 for ID Migration cleanup
		3 for Regeocode cleanup
	CleanupMode:
		0 Set this value for ID Migration cleanup, drop SYNONYM if exists.
		1 For regeocode cleanup, set this value if the job failed/canceled before the Merge step and the flag to drop schema is set to false (i.e. preserve schema for debugging)
		2 For regeocode cleanup, set this value if the job failed/canceled before the Merge step and the flag to drop schema is set to true.
		3 For regeocode cleanup, set this value if the job failed/canceled after the Merge step and the flag to drop schema is set to false (i.e. preserve schema for debugging)
		4 For regeocode cleanup, set this value if the job failed/canceled after the Merge step and the flag to drop schema is set to true.

Returns:	Nothing
====================================================================================================
*/
begin try
	set nocount on;

	declare @expoKey int;
	declare @FinishDate varchar(14);

	-- ID Migration cleanup: LookupMigrationInfo
	if (@prerequisiteID = 2)
	begin
		-- drop SYNONYM
		if exists (select 1 from sys.synonyms where name = 'MigrateLookupID')
		   drop synonym MigrateLookupID;
	end

	-- Regeocode cleanup: RegeocodeInfo
	if (@prerequisiteID = 3)
	begin
		-- Check for ExposureKey
		if (@nodeType = 64)
		begin
			set @expoKey = @nodeKey;

			-- Delete AvailableReport in Waiting status
			-- get all parent nodes
			create table #TreeMap (NodeKey int, NodeType int, InvalidateIR int, InvalidateExpReport int);
			insert #TreeMap exec absp_Inv_GetUpNodes @expoKey, 64, 0, 0;
			insert #TreeMap exec absp_Inv_GetDownNodes @expoKey, 64, 0, 0;
			delete a from AvailableReport a
				inner join absvw_AnalysisRunInfoByNodeKeyNodeType ai on a.AnalysisRunKey = ai.AnalysisRunKey
				inner join #TreeMap t on ai.NodeType = t.NodeType and ai.NodeKey = t.NodeKey
				and a.Status = 'Waiting';
			drop table #TreeMap;

			-- Regeocode failed before Merge step
			if (@cleanupMode in (1,2))
			begin
				begin tran;
					update RegeocodeInfo set FinishDate = '' where ExposureKey = @expoKey;
				commit tran;
			end

			-- Delete schema
			if (@cleanupMode in (2,4))
			begin
				exec absp_RegeocodeCleanup @expoKey;
			end

			-- Regeocode failed after Merge step
			if (@cleanupMode in (3,4))
			begin
				exec absp_Util_GetDateString @FinishDate output,'yyyymmddhhnnss';
				begin tran;
					update RegeocodeInfo set FinishDate = @FinishDate where ExposureKey = @expoKey;
					update ExposureInfo set GeocodeStatus = 'Failed' where ExposureKey = @expoKey;
				commit tran;
			end
		end
	end
end try

begin catch

end catch
