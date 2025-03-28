
if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewExposureClone') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewExposureClone
end
go

create procedure absp_TreeviewExposureClone
	@sourceParentType int,
	@sourceParentKey int,
	@targetParentType int,
	@targetParentKey int,
	@targetDB varchar(130)='',
	@taskKey int=-999,
	@skipBrowserDataRegeneration int = 0

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure clones exposure sets from one container node to another in the same user database or
across databases.
It can copy exposure sets from
- a primary portfolio to another primary portfolio in the same database or across databases
- a primary portfolio to a program/reinsurance account in the same database or across databases
- a program/reinsurance account to another program/reinsurance account in the same database or across databases
- a program/reinsurance account to a primary portfolio in the same database or across databases

Returns:       Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD @sourceParentType ^^  The sourceParentType of the exposure to be cloned.
##PD @sourceParentKey  ^^  The sourceParentKey of the exposure to be cloned.
##RD @targetParentType ^^  The targetParentType of the new clone portfolio.
##RD @targetParentKey  ^^  The targetParentKey of the new clone portfolio.
##RD @targetDB         ^^  The target database where the exposure is to be copied.
*/
as

BEGIN TRY

   set nocount on;

   declare @accountKey int;
   declare @newExposureKey int;
   declare @chunkThreshold int;
   declare @whereClause varchar(max);
   declare @newFldValueTrios varchar(max);
   declare @tabStep varchar(2);
   declare @sql varchar(max);
   declare @sSql nvarchar(max);
   declare @cursDictTbl_tname varchar(4000);
   declare @exposureKey int;
   declare @createdLookups int;
   declare @sourceDB varchar(130);
   declare @cnt int;
   declare @useChunk int;
   declare @lossRateSetKey int;
   declare @tmplName varchar(120);
   declare @mDate varchar(14);
   declare @newLossRateSetKey int;
   declare @taskProgressMsg varchar(max);
   declare @procID int;
   declare @extraWhereClause varchar(1000);

   set @procID = @@PROCID;

   set @createdLookups = 0;
   set @newExposureKey = 0;

	begin transaction;
	update TaskInfo set TaskDBProcessID=@@spid where TaskKey=@taskKey;
	commit transaction;

   if (@targetDB = '')
      set @targetDB = DB_NAME();

   set @sourceDB = DB_NAME();

   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB;
   execute absp_getDBName @sourceDB out, @sourceDB;

   --Find new lookups if targetDB is different
   if (@targetDB <> @sourceDB)
      exec @createdLookups = absp_FindNewDynamicLookups @targetDB;

   execute absp_GenericTableCloneSeparator @tabStep output;

   -- Add a task progress message
   set @taskProgressMsg = 'Cloning Exposure Set from Node Key, Node Type = ' + cast(@sourceParentKey as varchar(30)) + ',' + cast(@sourceParentType as varchar(30)) + ' to Target Node Key, Node Type ' + cast(@targetParentKey as varchar(30)) + ',' + cast(@targetParentType as varchar(30));
   exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

   --Clone Exposures--
   set @sql= 'select T1.ExposureKey,T1.LossRateSetKey from ExposureInfo T1 inner join ExposureMap T2 on T1.ExposureKey=T2.ExposureKey and T2.ParentKey = ' +
			cast(@sourceParentKey as varchar(30)) + ' and T2.ParentType = ' + cast(@sourceParentType as varchar(30));
   begin
		execute('declare c1 cursor forward_only global for '+@sql)
		open c1
		fetch c1 into @exposureKey,@lossRateSetKey
		while @@fetch_status=0
		begin

			--Check for LossRateSetKey --Task378
			set @newFldValueTrios=''
			if (@targetDB <> @sourceDB)
			begin
				select top(1) @tmplName=TemplateName,@mDate=ModifyDate from EQWCLossRate where LossRateSetKey =@lossRateSetKey
				set @newLossRateSetKey=-1
				set @sSql='select @newLossRateSetKey=LossRateSetKey from ' + @targetDB + '..EQWCLossRate where TemplateName =''' + @tmplName + ''' and ModifyDate=''' + @mDate + ''''
				execute sp_executesql @sSql,N'@newLossRateSetKey int output',@newLossRateSetKey output
				if @newLossRateSetKey =-1 or @newLossRateSetKey is null
				begin
					--Add entire set to target..EQWCLossRate
					set @sSql='select @newLossRateSetKey=max(LossRateSetKey) from ' + @targetDB + '..EQWCLossRate'
					execute sp_executesql @sSql,N'@newLossRateSetKey int output',@newLossRateSetKey output
					set @newLossRateSetKey=@newLossRateSetKey+1

					--Clone EQWCLossRate rows
					set @whereClause='LossRateSetKey ='+cast(@lossRateSetKey as varchar(30));
					set @newFldValueTrios = 'INT'+@tabStep+'LossRateSetKey'+@tabStep+cast(@newLossRateSetKey as varchar(30));
					execute  absp_ExposureTableCloneRecords 'EQWCLossRate', 1,@whereClause,@newFldValueTrios,0,@targetDB;
				end

				set @newFldValueTrios = 'INT'+@tabStep+'LossRateSetKey'+@tabStep+cast(@newLossRateSetKey as varchar(30));
			end

			--Clone ExposureInfo--
			set @whereClause = 'ExposureKey = '+ cast(@exposureKey as varchar(30));

			-- Add a task progress message
			set @taskProgressMsg = 'Cloning Exposure Key = ' + cast(@exposureKey as varchar(30));
			exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;


			execute @newExposureKey = absp_ExposureTableCloneRecords 'ExposureInfo',1,@whereClause,@newFldValueTrios,0,@targetDB;

			--Browser Info will not be cloned
   			--Set the IsBrowserDataGenerated flag to 'N'
			set @sql='update ' +  dbo.trim(@targetDB) + '..ExposureInfo set IsBrowserDataGenerated=''N'', status = ''Copying'' where ExposureKey='+ cast(@newExposureKey as varchar(30))
			execute(@sql); 

			set @newFldValueTrios = 'INT'+@tabStep+'ExposureKey'+@tabStep+cast(@newExposureKey as varchar(30));

			-- Add a task progress message
			set @taskProgressMsg = 'Cloning ExposureFile, ExposureTemplate, ExposureModel, ImportPostcodePartialMatch tables for Exposure Key = ' + cast(@exposureKey as varchar(30));
			exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;


			execute  absp_ExposureTableCloneRecords 'ExposureFile',    1,@whereClause,@newFldValueTrios,0,@targetDB;
			execute  absp_ExposureTableCloneRecords 'ExposureTemplate',1,@whereClause,@newFldValueTrios,0,@targetDB;
			execute  absp_ExposureTableCloneRecords 'ExposureModel',   0,@whereClause,@newFldValueTrios,0,@targetDB;
			execute  absp_ExposureTableCloneRecords 'ImportPostcodePartialMatch',   1,@whereClause,@newFldValueTrios,0,@targetDB;
			execute  absp_ExposureTableCloneRecords 'ExposureCacheInfo',1,@whereClause,@newFldValueTrios,0,@targetDB;

			set @extraWhereClause = @whereClause + ' and FinishDate = ''''';
			set @newFldValueTrios = 'INT'+@tabStep+'ExposureKey'+@tabStep+cast(@newExposureKey as varchar(30))+@tabStep ;
			set @newFldValueTrios = @newFldValueTrios + 'INT'+@tabStep+'ParentKey'+@tabStep+cast(@targetParentKey as varchar(30)) +@tabStep;
			set @newFldValueTrios = @newFldValueTrios + 'INT'+@tabStep+'ParentType'+@tabStep+cast(@targetParentType as varchar(30)) ;
			execute  absp_ExposureTableCloneRecords 'LookupMigrationInfo',    1,@extraWhereClause,@newFldValueTrios,0,@targetDB;
			execute  absp_ExposureTableCloneRecords 'ReGeocodeinfo',    0,@extraWhereClause,@newFldValueTrios,0,@targetDB;

			--Disable cloning ExposureValue because copy/paste is foreground task and needs to be fast
			--Once copy/paste is a background task, re-enable cloning ExposureValue
/*
			--Clone ExposureValue if targetDB is same as sourceDB since currency schema is the same
			--Use chunking
			if (@targetDB = @sourceDB)
				execute absp_ExposureTableCloneRecords 'ExposureValue',0,@whereClause,@newFldValueTrios,1,@targetDB;
*/

			--Get AccountKey and clone Account tables--
			set @accountKey = -1;
			select top (1) @accountKey = AccountKey from Account where ExposureKey=@exposureKey;

			--Check if account exists for the exposure--
			if (@accountKey <> -1)
			begin
   				-- clone Account with same AccountKey--
   				set @whereClause = 'ExposureKey = '+cast(@exposureKey as varchar(30)); --+ ' and AccountKey=' + cast(@accountKey as varchar(30))

   				execute absp_ExposureTableCloneRecords 'AccountStat',0,@whereClause,@newFldValueTrios,0,@targetDB,0;

   				-- now copy all the exposure related tables with lookups
   				declare cursHasLookup cursor fast_forward for
   					select TABLENAME from dbo.absp_Util_GetTableList('Exposure.Clone.HasLookup');
   				open cursHasLookup
   				fetch next from cursHasLookup into @cursDictTbl_tname;
   				while @@fetch_status = 0
   				begin

					-- Add a task progress message
					set @taskProgressMsg = 'Cloning ' + @cursDictTbl_tname + ' for Exposure Key = ' + cast(@exposureKey as varchar(30));
					exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;


					execute absp_ExposureTableCloneRecords @cursDictTbl_tname,1,@whereClause,@newFldValueTrios,1,@targetDB,1;
					fetch next from cursHasLookup into @cursDictTbl_tname;
   				end
   				close cursHasLookup
   				deallocate cursHasLookup

   				-- now copy all the exposure related tables without lookups
   				declare cursNoLookup cursor fast_forward for
   					select TABLENAME from dbo.absp_Util_GetTableList('Exposure.Clone');
   				open cursNoLookup
   				fetch next from cursNoLookup into @cursDictTbl_tname;
   				while @@fetch_status = 0
   				begin
   					--For tables with less number of columns, we use a larger chunk size and vice versa--
   					select @cnt=count(*) from Dictcol where tablename=@cursDictTbl_tname
   					if @cnt<15
   						set @useChunk=5
   					else
   						set @useChunk=1

					-- Add a task progress message
					set @taskProgressMsg = 'Cloning ' + @cursDictTbl_tname + ' for Exposure Key = ' + cast(@exposureKey as varchar(30));
					exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

				   	execute absp_ExposureTableCloneRecords @cursDictTbl_tname,1,@whereClause,@newFldValueTrios,@useChunk,@targetDB,0;
   				   fetch next from cursNoLookup into @cursDictTbl_tname;
   				end
   				close cursNoLookup
   				deallocate cursNoLookup


			end

			--Clone PolicyConditionName
			set @taskProgressMsg = 'Cloning PolicyConditionName for Exposure Key = ' + cast(@exposureKey as varchar(30));
			exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

			execute absp_ExposureTableCloneRecords PolicyConditionName,1,@whereClause,@newFldValueTrios,1,@targetDB,0;

			-- Add a task progress message
			set @taskProgressMsg = 'Cloning Import reports for Exposure Key = ' + cast(@exposureKey as varchar(30));
			exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

			-- Clone Import reports
			exec absp_TreeviewImportReportClone @exposureKey, @newExposureKey, @targetDB;

			--Clone Exposure LookupID Map Records
			exec absp_CopyExposureLookupIDMapRecords @exposureKey, @newExposureKey,@targetDB

			--Create ExposureMap record--
			set @sql='insert into ' + dbo.trim(@targetDB) + '..ExposureMap(ParentKey,ParentType,ExposureKey)
			              values(' + cast(@targetParentKey as varchar(30)) +','+ cast(@targetParentType as varchar(30)) +','+ cast(@newExposureKey as varchar(30))+'); ';
			execute(@sql);


			-- don't update counts unless each status field is 'Complete'
			if exists (select 1 from exposureinfo where exposurekey = @exposureKey and ImportStatus = 'Completed' and GeocodeStatus = 'Completed' and ReportStatus = 'Completed')
			begin
				set @sql= 'exec '+@targetDB+'..absp_ExposureCountUpdate '+str(@newExposureKey);
				execute(@sql);
			end

			--Fixed defect 9459
			--update exposureinfo status column with source exposureinfo status value
			set @sql='update ' +  dbo.trim(@targetDB) + '..ExposureInfo set status =  ( select status from exposureInfo where ExposureKey = ' + cast(@exposureKey as varchar(30)) + ' ) where ExposureKey='+ cast(@newExposureKey as varchar(30))
			execute(@sql);

			fetch c1 into @exposureKey,@lossRateSetKey
		end
		close c1
		deallocate c1

	end

	-- Add a task progress message
	set @taskProgressMsg = 'Droping all temporary tables';
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

	--If lookups are created, drop temp tables
	if @createdLookups = 1
	begin
		exec absp_DropTmpLookupTables
		if exists (Select 1 from tempdb.INFORMATION_SCHEMA.Tables Where Table_name='##TMP_LKUPCLONE_STATUS')
			delete from ##TMP_LKUPCLONE_STATUS  where DBNAME=@targetDB AND SP_ID =@@SPID;
	end

	-- Add a task progress message
	set @taskProgressMsg = 'Exposure copy completed succesfully.';
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

	--Check if the portfolio has any exposures--
	if exists(select 1 from ExposureInfo T1 inner join ExposureMap T2
		on T1.ExposureKey=T2.ExposureKey and T2.ParentKey = @sourceParentKey
		and T2.ParentType = @sourceParentType)
	begin
		--ExposureBrowserData needs to be regenerated--
		--If exposure filter is set for a different ExposureSet, then do not Regenerate--

		--Check if ExposureSetFilter is defined--
		if exists( select 1 from ExposureDataFilterInfo A inner join ExposureCategoryDef B on A.CategoryID=B.CategoryID where NodeKey=@targetParentKey and NodeType=@targetParentType )
		begin
			if not exists( select 1 from ExposureDataFilterInfo A inner join ExposureCategoryDef B on A.CategoryID=B.CategoryID  where B.Category='ExposureSetFilter' and NodeKey=@targetParentKey and NodeType=@targetParentType )
			begin
				set @sql = 'exec ' + @targetDB + '.dbo.absp_InfoTableAttribSetBrowserDataRegenerate ' + ltrim(rtrim(str(@targetParentType))) + ',' + ltrim(rtrim(str(@targetParentKey))) + ',1'
				execute(@sql)
				-- clean up statistics
				set @sql='delete from ' + @targetDB + '.dbo.FilteredStatReport where NodeKey=' + cast(@targetParentKey as varchar(30))
						+ ' and NodeType=' + cast (@targetParentType as varchar(30));
				exec(@sql);
			end
		end
		else
		begin
			set @sql = 'exec ' + @targetDB + '.dbo.absp_InfoTableAttribSetBrowserDataRegenerate ' + ltrim(rtrim(str(@targetParentType))) + ',' + ltrim(rtrim(str(@targetParentKey))) + ',1'
			execute(@sql)
			set @sql='delete from ' + @targetDB + '.dbo.FilteredStatReport where NodeKey=' + cast(@targetParentKey as varchar(30))
						+ ' and NodeType=' + cast (@targetParentType as varchar(30));
			exec(@sql);
		end

	end


	return @newExposureKey

END TRY

BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);

	-- Add a task progress message

	-- Get the Error Message
	exec absp_Util_GetErrorMessage @taskProgressMsg, @ProcName;
	set @taskProgressMsg = 'Exposure copy process failed.';
	exec absp_Util_AddTaskProgress @taskKey, @taskProgressMsg, @procID;

	-- Log it and raise error
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH