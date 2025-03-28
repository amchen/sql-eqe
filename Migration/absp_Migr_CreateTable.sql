if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_CreateTable') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_CreateTable
end

go

create procedure
absp_Migr_CreateTable @baseTableName VARCHAR(120) ,@newTableName VARCHAR(120) = '' ,@createIndex INT = 1 ,@dropFirstFlag INT = 0 ,@useSysTable INT = 0 
--returns integer
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will create a new table with the same structure as an existing base table.


Returns: An integer @retCode 
0 = success
1 = failure

====================================================================================================
</pre>
</font>
##FND_END 

##PD  @baseTableName ^^ A string containing the name of the base table.
##PD  @newTableName  ^^ A string containing the name of the new table.
##PD  @createIndex   ^^ An integer value specifying if an index has to be created on the new table or not(1=create the table with index,0=create the table without index).
##PD  @dropFirstFlag ^^ An integer value specifying if the table has to be recreated if it already exists(0=if the table exists then do nothing,1=if the table exists then drop it and create the table again). 
##PD  @useSysTable   ^^ An integer value specifying whether to use SYSTABLE or DICTBL for getting table field definitions.

##RD @retCode ^^ An integer value 0 on success and 1 on failure.
*/
AS
begin
 
   set nocount on
   
 /*
  This proc creates a table in the data dictionary (DICTTBL, DICTCOL, DICTIDX).

  Default createIndex = 1, create the table with indicies
  dropFirstFlag = 0, if the table exists, do nothing

  Options createIndex = 0, create the table without indicies
  dropFirstFlag = 1, if the table exists, drop it, then create the table

  Returns 0 on success, non-zero if failed
  */
   declare @baseTable VARCHAR(120)
   declare @newTable VARCHAR(120)
   declare @retCode INT
   declare @sql varchar(max)
   declare @sqlTbl varchar(max)
   execute absp_MessageEx 'absp_Migr_CreateTable - Started'
   set @retCode = 0
   set @baseTable = rtrim(ltrim(@baseTableName))
   if(@newTableName = '')
   begin
      set @newTable = ltrim(rtrim(@baseTable))
   end
   else
   begin
      set @newTable = rtrim(ltrim(@newTableName))
   end
  -- make sure the base table is valid first
   if exists(select 1 from DICTTBL where TABLENAME = @baseTable)
   begin
      if(@dropFirstFlag <> 0)
      begin
         if exists(select 1 from SYS.TABLES where NAME = @newTable)
         begin
        -- drop the table
            set @sql = 'drop table '+@newTable
            execute absp_MessageEx @sql
            execute(@sql)
            --commit work
         end
      end
      if not exists(select 1 from SYS.TABLES where NAME = @newTable)
      begin
         if(@useSysTable = 1)
         begin
            execute absp_Util_CreateSysTableScript @sqlTbl out, @baseTable,@newTable,'',@createIndex
         end
         else
         begin
            execute absp_Util_CreateTableScript @sqlTbl out,@baseTable,@newTable,'',@createIndex, 1
         end
         execute absp_MessageEx @sqlTbl
         execute(@sqlTbl)
         --commit work
      end
      else
      begin
         execute absp_MessageEx 'absp_Migr_CreateTable - Table exists'
      end
   end
   else
   begin
      set @retCode = 1
   end
   execute absp_MessageEx 'absp_Migr_CreateTable - Done'
   return @retCode
end






