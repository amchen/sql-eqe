if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GenericDeleter') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GenericDeleter;
end
go

create  procedure absp_GenericDeleter
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will use DELGRP and DELCTRL table to check the STATUS of all XXXXINFO table. If the
STATUS is DELETED then this procedure will delete the records from all the related tables based
on the XXXX_KEY (e.g. PPORT_KEY, CASE_KEY) in chunks. The tables that will be part of the delete
and the number of records to be deleted	is controlled by DELCTRL table.

This procedure uses 3 loops

	Loop 1 is used if we want to make sure that we are deleting 10000 records in 1 pass. Currently
	this loop is used only if WBU mode is detected.

	Loop 2 queries DELGRP and DELCTRL tables to get the list of all the INFO_TABLES (i.e. CASEINFO,
	PPRTINFO etc), INFO_TABLE_KEYS (CASE_KEY, PPORT_KEY etc) and their associated GROUP_ID.

	For each record in Loop 2, a query is executed to get the list of tables from where records will
	be deleted. DELCTRL table has all the information and in Loop 3, this table is queried to get the
	list of table names, the chunk size etc.

Returns: Nothing
====================================================================================================
</pre>
</font>
##BD_END
*/
begin try
	set nocount on;
	declare @sql varchar(2000);
	declare @sql1 varchar(2000);
	declare @nsql nvarchar(2000);
	declare @msg varchar(max);
	declare @me varchar(100);
	declare @delLimit int;
	declare @delCount int;
	declare @prevDelCount int;
	declare @numRecToDelete int;
	declare @infoTable varchar(120);
	declare @info_key_field varchar(120);
	declare @info_key int;
	declare @group_id int;
	declare @tableToDelete varchar(120);
	declare @keyName varchar(120);
	declare @extraWhere varchar(255);
	declare @joinClause varchar(2000);
	declare @maxDelPerTable int;
	declare @refTable varchar(120);
	declare @dbFilter varchar(50);
	declare @CleanType char(1);

	declare @isWBUDeletion int;
	declare @numRecDeleted int;
	-- This flag is used to know whether all the records are deleted or not.
	-- In Loop 2, we get the min key that is marked for deletion. If there is
	-- no record to delete then this flag is not set to 1 and the procedure will exit.
	declare @allDone int;
	-- total number of records deleted
	declare @curs2_groupId int;
	declare @curs2_infotable varchar(120);
	declare @curs2_keyField varchar(120);
	declare @curs2_NODE_TYPE int;
	declare @curs2 cursor;
	declare @resultsComparisonTable varchar(120);
	declare @sessionId int;
	declare @schemaname varchar(50);
	set @delCount = 0;
	-- Variable to store the delCount before the value of @delCount is modified inside loop 3.
	-- If (@delCount - @prevDelCount) == 0 then we know that all the records related to a given
	-- key is deleted and it is safe to delete the INFO record.
	set @prevDelCount = 0;

	set @delLimit = 100000 -- maximum total records to delete on one pass
	set @numRecToDelete = 100000;
	set @numRecDeleted = 0;
	set @me = 'absp_GenericDeleter';
	set @infoTable = '';
	set @info_key = 0;
	set @group_id = 0;
	set @dbFilter = '';
	set @tableToDelete = '';
	set @keyName = '';
	set @extraWhere = '';
	set @joinClause = '';
	set @maxDelPerTable = 0;
	set @refTable = '';
	set @isWBUDeletion = 0;
	set @allDone = 0;

	set @msg = @me+' Starting...';
	execute absp_Util_Log_HighLevel @msg,@me;

	-- Check if we have any records in table ResPStrWBU. This table is only populated if the server is
	-- processing any WBU request.
	-- If the deletion is performed for WBU then we need to ensure that we delete 10000 records in
	-- 1 pass. For non WBU mode we delete records for 1 @info_key but for WBU since we delete more
	-- portfolios we need to ensure that more records are deleted in one pass.

	if exists (select 1 from SYSOBJECTS where ID = object_id(N'ResPStrWBU') and objectproperty(id,N'IsTable') = 1)
	begin
		if exists (select top 1 1 from ResPStrWBU)
		begin
			set @isWBUDeletion = 1;
		end
	end

	-- Loop 1
	-- This loop is used only if we are running in WBU mode.
		-- Using Loop 2 we try to delete all the records for 1 set of keys. This is how it works when not in WBU mode.
		-- For WBU we need to delete more records and so we need to ensure that we actually delete 10000 records in 1 pass.
		-- After executing Loop 2 if the number of records deleted is less than 10000 then we will rerun Loop 2 util we
		-- delete 10000 records.

	while(1=1)
	begin
		-- Loop 2
		-- Loop thru DELGRP and process each group
		set @curs2 = cursor fast_forward for
			select GROUP_ID as groupId,rtrim(ltrim(INFOTABLE)) as INFOTABLE,IKEY_FIELD as keyField,NODE_TYPE
			from DELGRP
			order by GROUP_ID asc,NODE_TYPE asc
		open @curs2
		fetch next from @curs2 into @curs2_groupId,@curs2_infotable,@curs2_keyField,@curs2_NODE_TYPE
		while @@fetch_status = 0
		begin
			set @infoTable = @curs2_infotable;
			set @info_key_field = @curs2_keyField;
			set @group_id = @curs2_groupId;

			-- Get the lowest key that has the DELETED STATUS
			set @sql = 'select @info_key = min ('+ltrim(rtrim(@info_key_field))+') from '+ltrim(rtrim(@infoTable))+' where STATUS = ''DELETED''';
			execute absp_Util_Log_HighLevel @sql,@me;
			set @nsql = @sql;
            execute sp_executesql @nsql,N'@info_key int output',@info_key = @info_key output;

			set @info_key = ISNULL(@info_key,0);
			if(@info_key > 0)
			begin
				-- By default we assume there is nothing to delete.
				-- If we find a info key to delete then @allDone is set to false
				set @allDone = 1;
			set @msg = '-- Info table name = '+@infoTable+', Key to Delete '+ltrim(rtrim(str(@info_key)));
			execute absp_Util_Log_HighLevel @msg,@me;
			-- Loop 2
			-- Loop thru DELCTRL and get the list of all the tables that belongs to this group
			-- Some of the tables are only available in master DB so join with DICTCOL to
			-- get the correct list of tables.
			if exists(select 1 from RQEVersion where DbType = 'EDB')
			begin
				set @dbFilter = 't2.Cf_DB in (''L'', ''Y'')';
				exec absp_GenericDeleterSync @infoTable,@info_key_field,@info_key;
			end
			else
			begin
				set @dbFilter = 't2.Cf_DB_Ir in (''L'', ''Y'')';
			end
			set @sql1 = 'select rtrim(t1.TABLENAME) TABLENAME, REFTABLE, RKEYNAME, rtrim(EXTRAWHERE) EXTRAWHERE, rtrim(JOINCLAUSE) JOINCLAUSE, DEL_ROWS, CleanType' +
			            ' from DELCTRL t1 inner join DICTTBL t2 on t1.TABLENAME = t2.TABLENAME and ' + @dbFilter +
						' where GROUP_ID = ' + cast(@group_id as varchar(30)) + ' and TABLE_TYPE not in (''T'') order by GROUP_ID, SEQ_ID, t1.TABLENAME';
			execute absp_Util_Log_HighLevel @sql1,@me;
			-- Need to perform the check here since after deleting one group if the total
			-- number of records deleted is less then delLimit then we start deleting from
			-- the next group.
			if (@delCount > @delLimit or @numRecToDelete <= 0)
			begin
				goto endLp1;
			end

			-- before entering loop3 we need to set the prev delcount so afterwards we
			-- can check delCount to prevDelCount. In loop 3 if any record is deleted
			-- then @delCount - @prevDelCount should be greater than 0. If no record
			 -- is deleted for a given key then we can delete the Info record and then
			-- go back to loop 2 to delete the records for the next group.
			set @prevDelCount = @delCount;

			begin
				--Loop3
				execute('declare curs3 cursor global for '+@sql1);
				open curs3
				fetch next from curs3 into @tableToDelete,@refTable,@keyName,@extraWhere,@joinClause,@maxDelPerTable,@CleanType;
				while @@fetch_status = 0
				begin
					if(@joinClause is null)
					begin
						set @joinClause = '';
					end
					if(@extraWhere is null)
					begin
						set @extraWhere = '';
					end
					if(@maxDelPerTable <= 0)
					begin
						goto cntnLp3;
					end

					-- The main info table like APRRTINFO, PPRTINFO, RPRTINFO, PROGINFO and CASEINFO
					-- records cannot be deleted unless all other records gets deleted.
					if(ltrim(rtrim(@tableToDelete)) = ltrim(rtrim(@infoTable)) and (@delCount - @prevDelCount) > 0)
					begin
						goto cntnLp3;
					end

					if(@maxDelPerTable > @numRecToDelete)
					begin
						set @maxDelPerTable = @numRecToDelete;
					end

					-- @CleanType = 'P' means absp_BlobDiscard procedure
					if (@CleanType = 'P')
					begin
						set @sql = 'exec absp_BlobDiscard @tableToDelete, @info_key';
						set @sql = replace(@sql,'@tableToDelete',@tableToDelete);
						set @sql = replace(@sql,'@info_key',cast(@info_key as varchar(30)));
					end
					else
					begin
						if @tableToDelete='SnapshotInfo'
						begin
							--Delete Snapshot schema if any, associated to this node first--
							declare SCCurs cursor for 
								select SchemaName from SnapshotInfo A inner join Snapshotmap B on A.SnapshotKey=B.SnapshotKey 
								and B.NodeKey=@info_Key and B.NodeType=@curs2_NODE_TYPE
							open SCCurs
							fetch SCCurs into @schemaName
							while @@fetch_status=0
							begin
								execute absp_Util_CleanupSchema @schemaName
								fetch SCCurs into @schemaName
							end
							close SCCurs
							deallocate SCCurs
						end
						
						----------------------------------------------------------
					
						if(len(@joinclause)>0)
						begin
						  set @sql = 'DELETE TOP ('+ltrim(rtrim(str(@maxDelPerTable)))+') FROM '+ltrim(rtrim(@tableToDelete))+
									 ' '+ltrim(rtrim(@joinClause))+' and '+ltrim(rtrim(@refTable))+'.'+ltrim(rtrim(@keyName))+
									 ' = '+ltrim(rtrim(str(@info_key)))+ltrim(rtrim(@extraWhere));
						end
						else
						begin
						  set @sql = 'DELETE TOP ('+ltrim(rtrim(str(@maxDelPerTable)))+') FROM '+ltrim(rtrim(@tableToDelete))+
									 ' where '+ltrim(rtrim(@refTable))+'.'+ltrim(rtrim(@keyName))+
									 ' = '+ltrim(rtrim(str(@info_key)))+' '+ltrim(rtrim(@extraWhere));
						end
					end
					execute absp_Util_Log_HighLevel @sql,@me;
					execute(@sql);


					set @numRecDeleted = @@rowCount;
					set @msg = '-- Number of Records Deleted = ' + ltrim(rtrim(str(@numRecDeleted)));
					execute absp_Util_Log_HighLevel  @msg, @me;

					if (@numRecDeleted > 0)
					begin
						set @delCount = @delCount + @numRecDeleted;
						set @numRecToDelete = @numRecToDelete - @numRecDeleted;
					end

					-- Check if the maximum number of rows that can be deleted each pass is exceeded
					if @delCount > @delLimit or @numRecToDelete <= 0
					begin
						close curs3;
						deallocate curs3;
						goto endLp1;
					end
cntnLp3:
					fetch next FROM curs3 into @tableToDelete,@refTable,@keyName,@extraWhere,@joinClause,@maxDelPerTable,@CleanType;
				end --End loop3

				close curs3;
				deallocate curs3;
				end
			end
			fetch next from @curs2 into @curs2_groupId,@curs2_infotable,@curs2_keyField,@curs2_NODE_TYPE;
		end -- End loop2

		close @curs2;
		deallocate @curs2;

		-- If we are in WBU mode rerun loop 2. The procedure will execute based on the following if condition
		--		if @delCount > @delLimit or @numRecToDelete <= 0
		--       begin
		--			return
		--		end
		-- This check is done before entering Loop 3.

		if (@isWBUDeletion = 1 and @allDone = 1)
		begin
			set @msg = '-- Detected WBU mode. Last pass deleted ' + str(@delCount) + ' records. Rerun the loop to ensure that records are deleted';
			execute absp_Util_Log_HighLevel  @msg, @me;
			set @delCount = 0;
			set @allDone = 0;
		end
		else
		begin
			break; ---Exit Loop 1
		end
	end  -- End Loop1

	--Cleaning up dangling result comparison table--
	--===============================================
	--For each client session there is one result comparison table if the user performs result comparison which is of no use when the user logs off. 
	declare SCurs cursor for select User_ID from SessionW where Logoff_Dat<>''
	open SCurs
	fetch SCurs into @SessionId
	while @@fetch_status=0
	begin
		set @resultsComparisonTable='FinalResultsComparisonTbl_'+dbo.trim(cast(@sessionId as varchar(30)))
		if  exists(select 1 from sys.tables where name=@resultsComparisonTable) 	
		begin
			set @msg = @me+'drop Table ' + @resultsComparisonTable
			execute absp_Util_Log_HighLevel @msg,@me;	
			exec('drop Table ' + @resultsComparisonTable)
		end
		fetch SCurs into @SessionId
	end
	close SCurs
	deallocate SCurs
	--===================================================
	
endLp1:
	set @msg = @me+' Done';
	execute absp_Util_Log_HighLevel @msg,@me;
end try

-- Catch all exceptions since this is run again by the background deleter job
begin catch

end catch
