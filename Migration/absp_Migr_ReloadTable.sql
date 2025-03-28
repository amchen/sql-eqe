if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_ReloadTable') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_ReloadTable
end

go

create procedure absp_Migr_ReloadTable
    @tableName    varchar(100) ,
    @colNames     varchar(max) ,
    @whereSql     varchar(max) ,
    @tempPath     varchar(248) ,
    @makeIndex    bit = 1 ,
    @deleteTemp   bit = 1 ,
    @debugFlag    int = 1 ,
    @newTableName varchar(120) = '',
    @userName     varchar(100) = '',
    @password     varchar(100) = ''

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure modifies the structure of the given newTableName as that of the given tablename and
removes specified data from newTable. If newTableName is empty, the data of the base table is
changed as specified by the colNames and whereSql parameters.

Returns:      0 if migration takes place else returns 1
====================================================================================================
</pre>
</font>
##BD_END

##PD  @tableName ^^ The table whose structure is to be copied to newTable
##PD  @colNames ^^  The names of columns for which data migration is done
##PD  @whereSql ^^  The condition based on which migration is done
##PD  @tempPath ^^  The path which is used for the temporary file
##PD  @makeIndex ^^  A flag which indicates if the index is to be created
##PD  @deleteTemp ^^  A flag which indicates if the temporary text file used during migration is to be deleted
##PD  @debugFlag ^^  The debug Flag
##PD  @newTableName ^^  The name of the table for which the migration is done.

##RD @retCode ^^  0 if migration takes place else returns 1

*/
AS
begin

   set nocount on

  /*
  This function will create a temp table from a base table in DICTCOL,
  unload the base table using the colNames parameter, then reload the
  data back into the temp table.
  Optionally create indexes, delete temp files, and output debug messages.

  Returns 0 on success, non-zero on failure.
  */
   declare @retCode       int;
   declare @debug         int;
   declare @tempTable     varchar(120);
   declare @outputFile    varchar(255);
   declare @exists        int; -- my name
   declare @sSql          varchar(max);
   declare @me            varchar(max);
   declare @newTableName2 varchar(120);
   declare @dbname        varchar(100);
   declare @serverName    varchar(100);
   declare @qry           varchar(4000);
   declare @delStatus     int;
   declare @msgText       varchar(255);
   declare @errCode       int;

   -- init variables
   set @debug = @debugFlag
   set @retCode = 1
   set @tempTable = rtrim(ltrim(@tableName))+'_MIGRTMP'
   set @me = 'absp_Migr_ReloadTable: ' -- my name

   if(@newTableName = '')
   begin
      set @newTableName2 = rtrim(ltrim(@tableName))
   end
   else
   begin
      set @newTableName2 = rtrim(ltrim(@newTableName))
   end

   ------------ begin --------------------
   if @debug > 0
   begin
      set @msgText = @me+'starting'
      execute absp_MessageEx @msgText
   end

   if right(rtrim(@tempPath),1) = '/' or right(rtrim(@tempPath),1) = '\\' or right(rtrim(@tempPath),1) = '\'
   begin
      set @outputFile = rtrim(ltrim(@tempPath))+rtrim(ltrim(@tempTable))+'.TXT'
   end
   else
   begin
      set @outputFile = rtrim(ltrim(@tempPath))+'/'+rtrim(ltrim(@tempTable))+'.TXT'
   end

   -- SDG__00013615: TDM fails if the folder name begins with letter N due to escape char
   execute absp_Util_Replace_Slash @outputFile output, @outputFile

   -- Drop work table if it exists
   if exists(select 1 from SYS.TABLES where NAME = @tempTable)
   begin
      set @sSql = 'drop table '+@tempTable
      if @debug > 0
      begin
         execute absp_MessageEx @sSql
      end
      execute(@sSql)
   end

   -- Create work table with new columns and optional indicies
   if not exists(select 1 from SYS.TABLES where NAME = @tempTable)
   begin
      execute absp_Util_CreateTableScript @sSql output, @tableName,@tempTable
      if @debug > 0
      begin
         execute absp_MessageEx @sSql
      end
      execute(@sSql)
      if @makeIndex > 0
      begin
         execute absp_Util_CreateTableScript @sSql output,@tableName,@tempTable,'',2
         if len(@sSql) > 10
         begin
            if @debug > 0
            begin
               execute absp_MessageEx @sSql
            end
            execute(@sSql)
         end
      end
   end

   -- Unload source table data with default values for new columns
   set @dbname = DB_NAME();
   select @serverName = name from SYS.SERVERS where server_id=0

   if exists(select 1 from SYS.TABLES where NAME = @newTableName2)
   begin
      -- check for where clause
      if(select LEN(@whereSql)) > 1
      begin
		 set @qry='select '+ltrim(rtrim(@colNames))+' from ['+dbo.trim(@dbname)+']..'+ltrim(rtrim(@newTableName2))+' where '+@whereSql
      end
      else
      begin
		 set @qry='select '+ltrim(rtrim(@colNames))+' from ['+dbo.trim(@dbname)+']..'+ltrim(rtrim(@newTableName2))
      end

      --Defect SDG__00018799 - Call  absp_Util_UnloadData to unload table--
      exec @errCode = absp_Util_UnloadData  'Q',@qry,@outputFile,'|',@userName,@password

      if @errCode <> 0
      begin
		set @msgText = @me+' '+ERROR_MESSAGE()
		exec absp_messageEx  @msgText
		return
      end

      -- set exists flag
      set @exists = 1
      -- Drop source table after unload
      set @sSql = 'drop table '+@newTableName2
      if @debug > 0
      begin
         execute absp_MessageEx @sSql
      end
      execute(@sSql)
   end
   else
   begin
      set @exists = 0
   end

   -- Load source table data into work table and optionally delete data file
   if exists(select 1 from SYS.TABLES where NAME = @tempTable)
   begin
      -- Load only if we unloaded prior
      if(@exists > 0)
      begin
	     --Defect SDG__00018799 - Call  absp_Util_LoadData to load table--
         exec @errCode = absp_Util_LoadData  @tempTable,@outputFile,'|'
         if @errCode<>0
         begin
            set @msgText = @me+' '+ERROR_MESSAGE()
            exec absp_messageEx  @msgText
            return
         end
      end

      if @deleteTemp > 0
      begin
         execute @delStatus = absp_Util_DeleteFile  @outputFile
      end
   end

   -- Rename work table to source table name
   if not exists(select 1 from SYS.TABLES where NAME = @newTableName2)
   begin
      exec absp_Migr_RenameTable @tempTable,@newTableName2
      --set @sSql = 'exec sp_rename '+@tempTable+','+@newTableName2
      --if @debug > 0
      --begin
         --execute absp_MessageEx @sSql
      --end
      --execute(@sSql)
      set @retCode = 0
   end

   ------------ end --------------------
   if @debug > 0
   begin
      set @msgText = @me+'complete'
      execute absp_MessageEx @msgText
   end
   return @retCode
end
