if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_MigrateLookupIDUpdate') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_MigrateLookupIDUpdate;
end
go

create procedure absp_Migr_MigrateLookupIDUpdate
	@expoKey int,
	@Mode int = 0
as
/*
====================================================================================================
Purpose:	This procedure will clear out the LookupMigrationDetail by applying all records to Structure.
			We need to do this in case of a previous failure.
Parameter:	Mode=0 is do nothing, Mode=1 is apply update
Returns:	Nothing
====================================================================================================
*/
begin

	set nocount on;

	declare @chunkSize int;
	declare @minRow int;
	declare @maxRow int;
	declare @curRow int;
	declare @FinishDate varchar(14);
	declare @msg varchar(max);
	declare @me varchar(100);

	if (@Mode = 1)
	begin
		-- init
		set @me = 'absp_Migr_MigrateLookupIDUpdate: ';

		-- set chunkSize, if not present, default to zero = none
		select @chunkSize = cast(Bk_Value as int) from commondb..BkProp where Bk_Key = 'LookupID.ChunkSize';
		set @chunkSize = ISNULL(@chunkSize, 0);
		select @minRow = min(LookupMigrationDetailKey) from LookupMigrationDetail where IsApplied = 0;
		select @maxRow = max(LookupMigrationDetailKey) from LookupMigrationDetail where IsApplied = 0;
		set @minRow = ISNULL(@minRow, 1);
		set @maxRow = ISNULL(@maxRow, 1);
		if (@chunkSize = 0)
			set @chunkSize = @maxRow;
		set @curRow = @chunkSize;

		while (1 = 1)
		begin
			begin tran;

			update s set s.EQOccupancyTypeID = l.RQE16LookupID
			  from Structure s inner join LookupMigrationDetail l
			    on s.StructureRowNum = l.StructureRowNum
			   and l.CacheTypeDefID = 4
			   and l.LookupMigrationDetailKey between @minRow and @curRow;
			update s set s.EQStructureTypeID = l.RQE16LookupID
			  from Structure s inner join LookupMigrationDetail l
			    on s.StructureRowNum = l.StructureRowNum
			   and l.CacheTypeDefID = 5
			   and l.LookupMigrationDetailKey between @minRow and @curRow;
			update s set s.FLOccupancyTypeID = l.RQE16LookupID
			  from Structure s inner join LookupMigrationDetail l
			    on s.StructureRowNum = l.StructureRowNum
			   and l.CacheTypeDefID = 6
			   and l.LookupMigrationDetailKey between @minRow and @curRow;
			update s set s.FLStructureTypeID = l.RQE16LookupID
			  from Structure s inner join LookupMigrationDetail l
			    on s.StructureRowNum = l.StructureRowNum
			   and l.CacheTypeDefID = 7
			   and l.LookupMigrationDetailKey between @minRow and @curRow;
			update s set s.WSOccupancyTypeID = l.RQE16LookupID
			  from Structure s inner join LookupMigrationDetail l
			    on s.StructureRowNum = l.StructureRowNum
			   and l.CacheTypeDefID = 23
			   and l.LookupMigrationDetailKey between @minRow and @curRow;
			update s set s.WSStructureTypeID = l.RQE16LookupID
			  from Structure s inner join LookupMigrationDetail l
			    on s.StructureRowNum = l.StructureRowNum
			   and l.CacheTypeDefID = 24
			   and l.LookupMigrationDetailKey between @minRow and @curRow;

			update LookupMigrationDetail set IsApplied = 1
			 where LookupMigrationDetailKey between @minRow and @curRow;

			commit tran;

			if (@curRow >= @maxRow)
			begin
				-- Update LookupMigrationInfo
				exec absp_Util_GetDateString @FinishDate output,'yyyymmddhhnnss';
				begin tran;
					update LookupMigrationInfo set Status='Completed update', FinishDate = @FinishDate where ExposureKey = @expoKey;

					-- Done updating Structure
					truncate table LookupMigrationDetail;

					-- Update ExposureCacheInfo
					delete ExposureCacheInfo where ExposureKey = @expoKey;
					exec absp_GenerateExposureCacheInfo @expoKey;
				commit tran;
				break;
			end
			else
			begin
				-- Next chunk
				set @minRow = @curRow + 1;
				set @curRow = @curRow + @chunkSize;

				set @msg = @me + 'chunk';
				exec absp_MessageEx @msg;

				waitfor delay '00:00:05';
			end
		end
	end
end
