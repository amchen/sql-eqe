if exists(select * from SYSOBJECTS where ID = object_id(N'absp_MergeCleanUp') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_MergeCleanUp;
end
go

create procedure absp_MergeCleanUp
	@schemaName varchar(200),
	@mergeStep int,
	@mergeFailed int = 0,
	@exposureKey int = -1,
	@debug int = 0
as
/*
##BD_begin
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure cleans up database after the merge process.
	if mergeStep = 1 (chunkmerge), it simply cleans up the external schema.
	if mergeStep = 2 (PostTranslateMerge), it clean up the main tables and external schema.
	if mergeStep = 3 (PostGeocodeMerge), it cleans up the records from Structure table and copies records back from the back up table.
Returns: Nothing
====================================================================================================
</pre>
</font>

##PD  @schemaName ^^ The schema that is to be cleaned up
##PD  @exposureKey ^^ The exposureKey of the exposureSet that needs to be rolled back, in case merge fails
##PD  @mergeStep   ^^ 1 = chunkmerge, 2= PostTranslateMerge, 3 = PostGeocodeMerge
##PD  @mergeFailed ^^ Whether merge operation has failed or succeeded
##PD  @debug ^^ The deug mode

##BD_END

*/
begin
	set nocount on
	declare @chunksize int
	declare @sql varchar(max)
	declare @tableName varchar(200)
	declare @error_number 	int
	declare @backupTblName varchar(120)
	declare @minKey int
	declare @maxKey int
	declare @fieldNames varchar(max)

	if not exists (select 1 from sys.schemas where name =@schemaName )
	return

	set @chunksize = 50000
	set @backupTblName='Structure_BK'

	--For Cleanup on success, simply drop the schema--
	if @mergeFailed = 0 or @mergeStep = 1
	begin
		--drop schema--
		execute absp_Util_CleanupSchema @schemaName
		return
	end

	if @mergeStep=3 --PostGeocodeMerge--
	begin
		if not exists (select 1 from sys.tables where schema_name(schema_id)=@schemaName and name = @backupTblName)
		begin
			--backup does not exist -- drop schema--
			execute absp_Util_CleanupSchema @schemaName
			return
		end
	end

	if @mergeStep=2 --PostTranslateMerge--
		declare  c1 cursor for 	select  Name from sys.objects where schema_name(schema_id)= @schemaName and type ='U'
	else
		declare  c1 cursor for 	select  'Structure' --PostGeocodeMerge  and structure.bk exists

	open c1
	fetch c1 into @tableName
	while @@fetch_Status=0
	begin
		if @debug=1 print @tableName

		--Rollback cheanges if merge operation has failed
		if exists(select 1 from sys.tables where schema_name(schema_id)='dbo' and name=@tableName)
		begin
			if @debug=1 print @tableName
			--for each table delete in chunks
			while 1=1
			begin
			retry:
				begin try
					set @sql='delete top (' + dbo.trim(cast(@chunkSize as varchar)) + ') from ' + @tableName + '  where ExposureKey = ' + cast(@exposureKey as varchar)
					if @debug=1 print @sql
					exec(@sql)
					if @@rowCount=0
						break
				end try
				begin catch
					select @error_number = error_number()
					if @error_number  = 1205--deadlock
					begin
						exec absp_Util_Sleep 2000
						goto retry
					end
				end catch
			end
		end

		fetch c1 into @tableName
	end
	close c1
	deallocate c1

	if @mergeStep=3
	begin
		--Copy from the back up table--

		-- get the table field names from dictcol
   		execute absp_DataDictGetFields @fieldNames output, 'Structure', 1;

		set @minKey=1;
		select top (1) @maxKey = ROWCNT  from SYS.SYSINDEXES where object_name(ID)= @backupTblName and INDID<2 order by indid desc,rowcnt desc;

		set @chunkSize = 10000;
		chunk_lbl:
		while(@minKey <= @maxKey)
		begin

		 	set @sql = 'insert into Structure ' + ' ( '+@fieldNames+' )'+
		 	   ' select '+@fieldNames +' from   '+dbo.trim(@schemaName) +'.'+dbo.trim(@backupTblName) +' t '+' where StructureRowNum between '+cast(@minKey as char)+' and '+cast(@maxKey+@chunkSize -1 as char)
		        if(@debug > 0)  execute absp_MessageEx @sql;

		        execute(@sql);

		        set @minKey = @maxKey+@chunkSize;
      		end

	end

	--drop schema--
	execute absp_Util_CleanupSchema @schemaName;
end
