if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GenericTableCloneRecords') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GenericTableCloneRecords
end
go

create procedure absp_GenericTableCloneRecords
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
DB Version:    	MSSQL

Purpose:	This procedure at first creates a temporary table (with an autoincrementing primary key),
which is an exact replica of the specified table, except for some fields that are skipped
as per parameter. It then inserts records of this temporary table based on a condition (given
in a parameter) into the basetable.

Returns:    @theIdentity = value of the last autogenerating key from the temporary table

====================================================================================================

</pre>
</font>
##BD_END

##PD   @myTableName 	^^ Name of a table for which record cloning has to be done.
##PD   @skipKeyFieldNum	^^ Field name that has to be skipped (0 --> not to skipped , any other number of the field that has to be skipped)
##PD   @whereClause 	^^ Record cloning criteria.
##PD   @fieldValueTrios 	^^ Format, how to change field name in the temporary table created from the base table. This format has to be in accordance to the expected parameter of procodure "absp_StringSetFields"
##RD   @theIdentity     ^^ value of the last autogenerating key from the temporary table
*/
as
begin

   set nocount on

   declare @fieldNames varchar(max)
   declare @replNames varchar(max)
   declare @tempTable varchar(1000)
   declare @tmpTable varchar(1000)
   declare @sql varchar(max)
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

   set @debugFlag = 1;
   set @theIdentity = 0;

   set @modeFlag = @useChunking -- @modeFlag = 0 (original), @modeFlag = 1 (autokey table)

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
      -- In case of different currency DB
begin transaction
      if @updateLookupRefs=1 and  substring(@targetDB,2,len(@targetdb)-2)<>DB_NAME()
      begin
		execute absp_UpdateLookupRefs @sql out,@myTableName,@fieldNames,@fieldValueTrios,@whereClause,@targetDB
		set @sql = 'insert into '+ dbo.trim(@targetDB) + '..'+ dbo.trim(@myTableName) +' ( '+@fieldNames+' )'+ @sql
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
commit transaction
   end
   else
   begin
      -- autokey table
      -- create temp table with autoincrementing primary key
      set @tmpTable = @myTableName + cast(ROUND (999999 * RAND( (DATEPART(mm, GETDATE()) * 100000 ) + (DATEPART(ss, GETDATE()) * 1000 ) + DATEPART(ms, GETDATE()) ), 0) as varchar(30));
      set @tempTable = dbo.trim(@targetDB) + '..' + @tmpTable;

      execute('if exists(select 1 from sys.tables where name= '''+@tempTable +''' ) begin drop table '+@tempTable+' end');

      --Check if the table hasIdentity column
      select @HasIdentity = isnull(objectproperty ( object_id(@myTableName) , 'TableHasIdentity' ) , -1)
      If @HasIdentity = 0
      begin
         set @aKey = 1
      end
      else
      begin
         set @aKey = 0
      end

      execute absp_Util_CreateTableScript @sql output, @myTableName, @tmpTable,'',0,0,@aKey,@targetDB;

      if(@debugFlag > 0)
      begin
         execute absp_MessageEx 'Create autokey temp table'
         execute absp_MessageEx @sql
      end
      execute(@sql)

      if(@debugFlag > 0)
      begin
         set @msgText = ' begin transaction; insert into '+@tempTable+' ( '+@fieldNames+' )'+' select '+@replNames+' from   '+@myTableName+'  MT   WHERE MT.'+@whereClause+'; commit transaction; '
         execute absp_MessageEx @msgText
      end

      if @updateLookupRefs=1 and  substring(@targetDB,2,len(@targetdb)-2)<>DB_NAME()
      begin
		execute absp_UpdateLookupRefs @sql out,@myTableName,@fieldNames,@fieldValueTrios,@whereClause,@targetDB
		set @sql = ' begin transaction; insert into '+@tempTable+' ( '+@fieldNames+' )'+ @sql+'; commit transaction; '
		execute absp_MessageEx @sql
		execute(@sql)

      end
      else
        execute(' begin transaction; insert into '+@tempTable+' ( '+@fieldNames+' )'+' select '+@replNames+' from   '+@myTableName+'  mt   where mt.'+@whereClause+'; commit transaction; ')

      ---Find the IDENTITY COLUMN------
      if @HasIdentity = 1
      begin
	select @colname = name from sys.identity_columns where  object_id=object_id(@myTableName)
      end
      else
      begin
           set @colname= 'AUTOKEY'
      end
      set @sSql = 'select @minAutoKey = min('+@colname+'),@maxAutoKey = max('+@colname+')  from '+@tempTable
      execute sp_executesql @sSql,N'@minAutoKey int output,@maxAutoKey int output',@minAutoKey output,@maxAutoKey output

      -- insert 1000 records in each pass
      set @chunkSize = 1000
      chunk_lbl:
      while(@minAutoKey <= @maxAutoKey)
      begin

begin transaction
 	     set @sql = 'insert into '+ dbo.trim(@targetDB) + '..' + @myTableName+' ( '+@fieldNames+' )'+' select '+@fieldNames+' from   '+@tempTable+' t '+' where t.'+@colname+' between '+cast(@minAutoKey as char)+' and '+cast(@minAutoKey+@chunkSize -1 as char)

         if(@debugFlag > 0)
         begin
            execute absp_MessageEx @sql
         end
         execute(@sql)

         if @@rowcount>0
         	select  @theIdentity = IDENT_CURRENT (dbo.trim(@targetDB) + '..'+ dbo.trim(@myTableName))
commit transaction

         set @minAutoKey = @minAutoKey+@chunkSize
      end
      execute('drop table '+@tempTable)
   end

   return COALESCE(@theIdentity, 0);
end
