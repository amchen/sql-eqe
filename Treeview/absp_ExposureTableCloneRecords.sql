if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_ExposureTableCloneRecords') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_ExposureTableCloneRecords
end
go

create procedure absp_ExposureTableCloneRecords
	@myTableName varchar(1000),
	@skipKeyFieldNum int,
	@whereClause varchar(max),
	@fieldValueTrios varchar(max),
	@useChunking int = 0,
	@targetDB varchar(130)='',
	@updateLookupRefs int=0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This procedure clones records of a table, based on the given Where Clause.
Returns:    @theIdentity = value of the last autogenerating key from the temporary table
====================================================================================================
</pre>
</font>
##BD_END

##PD   @myTableName 	^^ Name of a table for which record cloning has to be done.
##PD   @skipKeyFieldNum	^^ Field name that has to be skipped (0 --> not to skipped , any other number of the field that has to be skipped)
##PD   @whereClause 	^^ Record cloning criteria.
##PD   @fieldValueTrios ^^ Format, how to change field name in the temporary table created from the base table. This format has to be in accordance to the expected parameter of procodure "absp_StringSetFields"
##RD   @useChunking     ^^ Whether chunking will be used, if used, we get the chunk size
##RD   @targetDB     ^^ The target DB Name
##RD   @updateLookupRefs     ^^ Whether to update lookup references

*/
as
begin

   set nocount on

   declare @fieldNames varchar(max)
   declare @replNames varchar(max)
   declare @tempTable varchar(1000)
   declare @tmpTable varchar(1000)
   declare @sql varchar(max)
   declare @sql2 varchar(max)
   declare @sSql nvarchar(4000)
   declare @modeFlag int
   declare @debugFlag int
   declare @minAutoKey int
   declare @maxAutoKey int
   declare @chunkSize int
   declare @theIdentity int
   declare @colname varchar(2000)
   declare @hasIdentity int
   declare @aKey int
   declare @msgText varchar(255)
   declare @where varchar(max)
   declare @keyfld int
   declare @rcount int

   set @debugFlag = 0;
   set @theIdentity = 0;

   set @modeFlag = @useChunking -- @modeFlag = 0 (original), @modeFlag > 1  (use chunking)

   if @targetDB=''
   	set @targetDB = DB_NAME();

   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB;

   -- get the table field names from dictcol
   execute absp_DataDictGetFields @fieldNames output, @myTableName, @skipKeyFieldNum;

   -- replace those filled with overrides from user
   execute absp_StringSetFields @replNames output, @fieldNames, @fieldValueTrios;

   -- original mode
   if(@modeFlag = 0)
   begin
    begin transaction;
   	-- In case of different currency DB
    if @updateLookupRefs=1 and  substring(@targetDB,2,len(@targetdb)-2)<>DB_NAME()
    begin
      execute absp_UpdateLookupRefs @sql out,@myTableName,@fieldNames,@fieldValueTrios,@whereClause,@targetDB
      set @sql = ' insert into '+ dbo.trim(@targetDB) + '..'+ dbo.trim(@myTableName) +' ( '+@fieldNames+' )'+ @sql
    end
    else
      set @sql = ' insert into '+ dbo.trim(@targetDB) + '..'+ dbo.trim(@myTableName) +' ( '+@fieldNames+' )'+' select  '+@replNames+' from  '+@myTableName+'  mt   where mt.'+@whereClause

    if(@debugFlag > 0)
    begin
      execute absp_MessageEx @sql
    end

    execute(@sql)

    if @@rowcount>0
    begin
      select  @theIdentity = IDENT_CURRENT (dbo.trim(@targetDB) + '..'+ dbo.trim(@myTableName))
    end
    commit transaction;
  end
  else
   begin

	---Find the IDENTITY COLUMN------
	select @colname = name from sys.identity_columns where  object_id=object_id(@myTableName)
 	if @myTableName='Account' set @colName='AccountKey'

 	set @minAutoKey=-1
	set @sSql = 'select @minAutoKey = min('+@colname+') ,@maxAutoKey = max('+@colname+') from '+@myTableName +'  mt   where mt.'+@whereClause
	execute sp_executesql @sSql,N'@minAutoKey int output,@maxAutoKey int output',@minAutoKey output,@maxAutoKey output

 	--If there are rows to clone--
 	if @minAutoKey <> -1
 	begin

		if @updateLookupRefs=1 and  substring(@targetDB,2,len(@targetdb)-2)<>DB_NAME()
			execute absp_UpdateLookupRefs @sql out,@myTableName,@fieldNames,@fieldValueTrios,@whereClause,@targetDB
		else
			set @sql = 'select '+@replNames+'  from '+@myTableName +'  mt   where mt.'+@whereClause

		set @chunkSize = 10000 * @modeFlag;

		chunk_lbl:
		while (@minAutoKey <= @maxAutoKey)
		begin

			set @sql2 = ' insert into '+ dbo.trim(@targetDB) + '..' + @myTableName+' ( '+@fieldNames+' )'+
				@sql+ ' and mt.'+@colname+' between '+cast(@minAutoKey as char)+' and '+cast(@minAutoKey+@chunkSize -1 as char) + ' OPTION(RECOMPILE); ';

			if(@debugFlag > 0)
			begin
				execute absp_MessageEx @sql2;
			end

		    begin transaction

			execute(@sql2);
            set @rcount = @@rowcount;

			commit transaction

			if @rcount > 0
				select @theIdentity = IDENT_CURRENT (dbo.trim(@targetDB) + '..' + dbo.trim(@myTableName));

			set @minAutoKey = @minAutoKey + @chunkSize;

		end
   	end
   end
   return COALESCE(@theIdentity, 0);
end
