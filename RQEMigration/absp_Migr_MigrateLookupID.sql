if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_MigrateLookupID') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_MigrateLookupID;
end
go

create procedure absp_Migr_MigrateLookupID
	@NodeKey int = 0,
	@NodeType int = 0,
	@Mode int = 1
as
/*
====================================================================================================
Purpose:	This procedure will migrate lookup IDs.
			If called by the background thread, it will migrate only a chunk of lookup IDs per iteration.
			Eventually all lookup IDs in the EDB will be migrated.
			If called by the foreground thread, it will migrate all lookup IDs for the NodeKey and NodeType in one iteration.
Parameter:	NodeKey and NodeType of interest, Mode=0 is background, Mode=1 is foreground
Returns:	Nothing
Example:	exec absp_Migr_MigrateLookupID 0, 0, 0	-- background mode
			exec absp_Migr_MigrateLookupID 2, 2, 1	-- foreground mode, Primary Portfolio
====================================================================================================
*/
begin try

	set nocount on;

	-- variables
	declare @LookupTableName varchar(100);
	declare @CountryCode varchar(3);
	declare @CacheTypeDefID integer;
	declare @RQE15LookupID integer;
	declare @RQE16LookupID integer;
	declare @FinishDate varchar(14);
	declare @expoKey integer;
	declare @msg varchar(max);
	declare @me varchar(100);
	declare @chunkSize int;
	declare @minRow int;
	declare @maxRow int;
	declare @curRow int;
	declare @statusMsg varchar(50);

	-- init
	set @me = 'absp_Migr_MigrateLookupID: ';

	set @msg = @me + 'Starting...';
	exec absp_MessageEx @msg;

	-- check for EDB
	if not exists (select 1 from RQEVersion where DbType = 'EDB')
	begin
		set @msg = @me + 'This is not an EDB database...return';
		exec absp_MessageEx @msg;
		return;
	end

	-- check for EDB and VERSION 16.00.00
	if (select max(RQEVersion) from RQEVersion) <> '16.00.00'
	begin
		set @msg = @me + 'This EDB database is not RQEVersion 16.00.00...return';
		exec absp_MessageEx @msg;
		return;
	end

RetrySynonym:
	begin try
		if (@Mode = 1)
		begin
			-- if in foreground mode, wait for SYNONYMS
			while (select 1 from sys.synonyms with (NOLOCK) where name = 'MigrateLookupID')=1
			   waitfor delay '00:00:10';
		end
		else
		begin
			-- if in background mode, return
			if exists (select 1 from sys.synonyms with (NOLOCK) where name = 'MigrateLookupID')
			begin
				return;
			end
		end

		-- create SYNONYM
		create synonym MigrateLookupID for [MigrateLookupID];
	end try
	begin catch
		waitfor delay '00:00:07';
		goto RetrySynonym;
	end catch

	-- check if we have previous records to apply
	if exists (select top 1 1 from LookupMigrationInfo where Status='Updating')
	begin
		select top 1 @expoKey = ExposureKey from LookupMigrationInfo where Status='Updating';
		exec absp_Migr_MigrateLookupIDUpdate @expoKey, 1;
	end

	-- create temp table to populate in absp_PopulateChildList
	create table #NODELIST (NODE_KEY INT, NODE_TYPE INT, PARENT_KEY INT, PARENT_TYPE INT);

	-- get all child nodes and populate #NODELIST
  	execute absp_PopulateChildList @NodeKey, @NodeType;

	-- insert record for self
	insert #NODELIST (NODE_KEY,NODE_TYPE) values (@NodeKey, @NodeType);

	-- remove non-Exposure parents
	delete from #NODELIST where NODE_TYPE not in (2,7,27);

	create table #expoList (ExposureKey integer);

	-- Determine ExposureKeys to process
	if (@Mode = 1)
	begin
		-- foreground mode
		insert #expoList select distinct l.ExposureKey from LookupMigrationInfo l inner join #NODELIST n on l.ParentKey=n.NODE_KEY and l.ParentType=n.NODE_TYPE and l.FinishDate='';
	end
	else
	begin
		-- background mode
		insert #expoList select top 1 l.ExposureKey from LookupMigrationInfo l inner join #NODELIST n on l.ParentKey=n.NODE_KEY and l.ParentType=n.NODE_TYPE and l.FinishDate='' order by l.LookupMigrationInfoKey asc;
	end

	-- set chunkSize, if not present, default to zero = none
	select @chunkSize = cast(Bk_Value as int) from commondb..BkProp where Bk_Key = 'LookupID.ChunkSize';
	set @chunkSize = ISNULL(@chunkSize, 0);

	update LookupMigrationInfo set Status='Pending' where ExposureKey in (select ExposureKey from #expoList);

	-- loop 1: By ExposureKey
	declare curMigrateRQE15Exposure cursor fast_forward for select ExposureKey from #expoList;
	open curMigrateRQE15Exposure;
	fetch next from curMigrateRQE15Exposure into @expoKey;
	while @@fetch_status=0
	begin
		set @msg = @me + 'Updating ExposureKey=' + cast(@expoKey as varchar(20));
		exec absp_MessageEx @msg;

		-- Status
		begin tran;
			update LookupMigrationInfo set Status='Running' where ExposureKey = @expoKey;
		commit tran;

		truncate table LookupMigrationDetail;

		-- Populate LookupMigrationDetail
		set @msg = @me + 'Populate LookupMigrationDetail';
		exec absp_MessageEx @msg;

		begin tran;
		insert LookupMigrationDetail (StructureRowNum, CacheTypeDefID, LookupTableName, CountryCode, RQE15LookupID, RQE16LookupID, IsApplied)
			select s.StructureRowNum, l.CacheTypeDefID, l.LookupTableName, l.CountryCode, s.EQOccupancyTypeID, l.RQE16LookupID, 0 as IsApplied
			  from Structure s inner join LookupMigrationInfo l
				on s.ExposureKey = l.ExposureKey
			   and s.CountryCode = l.CountryCode
			   and s.EQOccupancyTypeID = l.RQE15LookupID
			   and l.CacheTypeDefID = 4
			   --and l.LookupTableName = 'EOTDL'
			   and l.ExposureKey = @expoKey
			union
			select s.StructureRowNum, l.CacheTypeDefID, l.LookupTableName, l.CountryCode, s.EQStructureTypeID, l.RQE16LookupID, 0 as IsApplied
			  from Structure s inner join LookupMigrationInfo l
				on s.ExposureKey = l.ExposureKey
			   and s.CountryCode = l.CountryCode
			   and s.EQStructureTypeID = l.RQE15LookupID
			   and l.CacheTypeDefID = 5
			   --and l.LookupTableName = 'ESDL'
			   and l.ExposureKey = @expoKey
			union
			select s.StructureRowNum, l.CacheTypeDefID, l.LookupTableName, l.CountryCode, s.FLOccupancyTypeID, l.RQE16LookupID, 0 as IsApplied
			  from Structure s inner join LookupMigrationInfo l
				on s.ExposureKey = l.ExposureKey
			   and s.CountryCode = l.CountryCode
			   and s.FLOccupancyTypeID = l.RQE15LookupID
			   and l.CacheTypeDefID = 6
			   --and l.LookupTableName = 'FOTDL'
			   and l.ExposureKey = @expoKey
			union
			select s.StructureRowNum, l.CacheTypeDefID, l.LookupTableName, l.CountryCode, s.FLStructureTypeID, l.RQE16LookupID, 0 as IsApplied
			  from Structure s inner join LookupMigrationInfo l
				on s.ExposureKey = l.ExposureKey
			   and s.CountryCode = l.CountryCode
			   and s.FLStructureTypeID = l.RQE15LookupID
			   and l.CacheTypeDefID = 7
			   --and l.LookupTableName = 'FSDL'
			   and l.ExposureKey = @expoKey
			union
			select s.StructureRowNum, l.CacheTypeDefID, l.LookupTableName, l.CountryCode, s.WSOccupancyTypeID, l.RQE16LookupID, 0 as IsApplied
			  from Structure s inner join LookupMigrationInfo l
				on s.ExposureKey = l.ExposureKey
			   and s.CountryCode = l.CountryCode
			   and s.WSOccupancyTypeID = l.RQE15LookupID
			   and l.CacheTypeDefID = 23
			   --and l.LookupTableName = 'WOTDL'
			   and l.ExposureKey = @expoKey
			union
			select s.StructureRowNum, l.CacheTypeDefID, l.LookupTableName, l.CountryCode, s.WSStructureTypeID, l.RQE16LookupID, 0 as IsApplied
			  from Structure s inner join LookupMigrationInfo l
				on s.ExposureKey = l.ExposureKey
			   and s.CountryCode = l.CountryCode
			   and s.WSStructureTypeID = l.RQE15LookupID
			   and l.CacheTypeDefID = 24
			   --and l.LookupTableName = 'WSDL'
			   and l.ExposureKey = @expoKey;
		commit tran;
/*
		-- loop 2: Update LookupIDs
		set @msg = @me + 'Update LookupIDs';
		exec absp_MessageEx @msg;

		begin tran;
			declare curMigrateRQE15ID cursor fast_forward for
				select LookupTableName, CountryCode, RQE15LookupID, RQE16LookupID, CacheTypeDefID
					from systemdb..MigrateRQE15IDstoRQE16IDs order by UpdateStatementOrder asc;

			open curMigrateRQE15ID;
			fetch next from curMigrateRQE15ID into @LookupTableName, @CountryCode, @RQE15LookupID, @RQE16LookupID, @CacheTypeDefID;
			while @@fetch_status=0
			begin
				update LookupMigrationDetail set LookupID=@RQE16LookupID where CacheTypeDefID=@CacheTypeDefID and CountryCode=@CountryCode and LookupID=@RQE15LookupID;
				fetch next from curMigrateRQE15ID into @LookupTableName, @CountryCode, @RQE15LookupID, @RQE16LookupID, @CacheTypeDefID;
			end
			close curMigrateRQE15ID;
			deallocate curMigrateRQE15ID;

			update l set l.LookupID = m.RQE16LookupID
			  from LookupMigrationDetail l inner join systemdb..MigrateRQE15IDstoRQE16IDs m
			    on l.CacheTypeDefID = m.CacheTypeDefID
			   and l.CountryCode = m.CountryCode
			   and l.LookupID = m.RQE15LookupID;
		commit tran;
*/

		select @minRow = min(LookupMigrationDetailKey) from LookupMigrationDetail where IsApplied = 0;
		select @maxRow = max(LookupMigrationDetailKey) from LookupMigrationDetail where IsApplied = 0;
		set @minRow = ISNULL(@minRow, 1);
		set @maxRow = ISNULL(@maxRow, 1);
		if (@chunkSize = 0)
			set @chunkSize = @maxRow;
		set @curRow = @chunkSize;

		-- Update Structure table
		set @msg = @me + 'Update Structure table';
		exec absp_MessageEx @msg;

		-- Status
		begin tran;
			update LookupMigrationInfo set Status='Updating' where ExposureKey = @expoKey;
		commit tran;

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
				-- Done updating Structure
				break;
			end
			else
			begin
				-- Next chunk
				set @minRow = @curRow + 1;
				set @curRow = @curRow + @chunkSize;
				waitfor delay '00:00:05';
			end
		end

		begin
			-- Update ReportFilterInfo
			-- It turns out we do NOT need to update ReportFilterInfo since there are no filters by structure or occupancy types

			-- Update LookupMigrationInfo
			set @msg = @me + 'Update LookupMigrationInfo table';
			exec absp_MessageEx @msg;

			if (@Mode = 1)
				set @statusMsg = 'Completed foreground';
			else
				set @statusMsg = 'Completed background';
			exec absp_Util_GetDateString @FinishDate output,'yyyymmddhhnnss';

			begin tran;
				update LookupMigrationInfo set Status = @statusMsg, FinishDate = @FinishDate where ExposureKey = @expoKey;

				-- Done updating Structure
				truncate table LookupMigrationDetail;

				-- Update ExposureCacheInfo
				set @msg = @me + 'Update ExposureCacheInfo table';
				exec absp_MessageEx @msg;
				delete ExposureCacheInfo where ExposureKey = @expoKey;
				exec absp_GenerateExposureCacheInfo @expoKey;
			commit tran;
		end

		fetch next from curMigrateRQE15Exposure into @expoKey;
	end
	close curMigrateRQE15Exposure;
	deallocate curMigrateRQE15Exposure;

	drop table #NODELIST;
	drop table #expoList;

	-- drop SYNONYM
	set @msg = @me + 'drop synonym MigrateLookupID';
	exec absp_MessageEx @msg;
	if exists (select 1 from sys.synonyms where name = 'MigrateLookupID')
	   drop synonym MigrateLookupID;

	set @msg = @me + 'Done';
	exec absp_MessageEx @msg;

end try

begin catch
	declare @ProcName varchar(100),
			@mesg as varchar(1000),
			@module as varchar(100),
			@ErrorSeverity varchar(100),
			@ErrorState int,
			@ErrorMsg varchar(4000);

	-- drop SYNONYM
	if exists (select 1 from sys.synonyms where name = 'MigrateLookupID')
	   drop synonym MigrateLookupID;

	select @ProcName = object_name(@@procid);
    select
		@module = isnull(ERROR_PROCEDURE(),@ProcName),
        @mesg='"'+ERROR_MESSAGE()+'"'+
        		'  Line: '+cast(ERROR_LINE() as varchar(10))+
				'  No: '+cast(ERROR_NUMBER() as varchar(10))+
				'  Severity: '+cast(ERROR_SEVERITY() as varchar(10))+
        		'  State: '+cast(ERROR_STATE() as varchar(10)),
        @ErrorSeverity=ERROR_SEVERITY(),
        @ErrorState=ERROR_STATE(),
        @ErrorMsg='Exception: Top Level '+@ProcName+'. Occurred in '+@module+'. Error: '+@mesg;
	raiserror (
		@ErrorMsg,	-- Message text
		@ErrorSeverity,	-- Severity
		@ErrorState		-- State
	)
	return 99;
end catch
