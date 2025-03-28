if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_CheckIndex') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_CheckIndex
end

go
create procedure absp_Migr_CheckIndex @createMissing int = 0 ,@indexName varchar(max) = '' 
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure compares the actual index schemas against the data dictionary (DICTIDX) and returns the 
number of index mismatches found. It creates the missing indexes if createMissing flag is on.

Returns:      0 if there are no missing indexes
              non-zero, if missing, the count of the missing indexes
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @createMissing ^^  A flag which indicates if the missing indexes are to be created
##PD  @indexName ^^  The name of the index that is to be checked

##RD @retCode ^^  0 if there are no missing indexes, non-zero, if missing, the count of the missing indexes
*/
as
begin
  /*
  This proc checks actual index schemas against the data dictionary (DICTIDX)
  and outputs error messages for missing indexes.

  Default createMissing = 0, check only
  createMissing = 1, create missing indices

  Default indexName = '', all indexes
  indexName = string, specific index

  Return = 0, no missing indices
  Return = non-zero, count of missing indices
  */
  
  set nocount on
   
   declare @retCode int
   declare @sSql varchar(max)
   declare @sSql2 varchar(max)
   declare @iname varchar(120)
   declare @tname varchar(120)
   declare @isu char(2)
   declare @msg varchar(max)
   
   declare @cursDictidx_indxName varchar(120)
   declare @cursDictidx_tblName varchar(120)
   declare @cursTmp_FN varchar(40)
      
   create table #FLDSORTED
      (
         INAME varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS  null,
         FNAME varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS  null
   )
   
   set @retCode = 0
   set @msg = cast(GetDate() as varchar) + ': absp_Migr_CheckIndex - Started'
   exec absp_Util_LogIt @msg, 1, 'absp_Migr_CheckIndex'
   
   declare cursDictidx cursor fast_forward for select distinct rtrim(ltrim(INDEXNAME)) ,rtrim(ltrim(TABLENAME))  from DICTIDX
   open cursDictidx
   fetch next from cursDictidx into @cursDictidx_indxName,@cursDictidx_tblName
   while @@fetch_status = 0
   begin
      set @iname = @cursDictidx_indxName
      set @tname = @cursDictidx_tblName
    -- specific index requested
      if (@indexName <> '')
      begin
         set @iname = rtrim(ltrim(@indexName))
      end
      if (@tname <> 'ZZZ' and @tname <> '' and @tname <> ' ' and @iname = @cursDictidx_indxName)
      begin
      -- make sure table exists first
         if exists(select 1 from SYS.TABLES where NAME = @tname)
         begin
            if not exists(select 1 from SYSINDEXES where object_name(id) = @tname and name = @iname)
            begin
            
               set @retCode = @retCode+1
               set @msg = cast(GetDate() as varchar) + ': **** Table '+@tname+' missing index '+@iname+' ****'
               exec absp_Util_LogIt @msg, 1, 'absp_Migr_CheckIndex'
               
               if (@createMissing > 0)
               begin

                  set @msg = cast(GetDate() as varchar) + ': **** Auto-create missing index '+@iname+' ****'
                  exec absp_Util_LogIt @msg, 1, 'absp_Migr_CheckIndex'
                  
                  -- check if index is unique
                  select  top 1 @isu = ISUNIQUE  from DICTIDX where INDEXNAME = @iname and TABLENAME = @tname
                  
                  -- get each distinct index name order by name
                  truncate table #FLDSORTED
                 
                  insert into #FLDSORTED select rtrim(ltrim(INDEXNAME)),rtrim(ltrim(FIELDNAME)) from DICTIDX
                         where INDEXNAME = @iname and TABLENAME = @tname order by FIELDORDER asc
                  set @sSql = '  create '
                  if @isu = 'Y'
                  begin
                     set @sSql = @sSql+' unique '
                  end
                  set @sSql = @sSql+' index '+@iname+' on '+@tname+' ('
                  set @sSql2 = ''
                  
                  -- get each field name for the index
                  exec absp_Util_GenInList @sSql2 out, 'select FNAME  from #FLDSORTED'
                  set @sSql2 = replace(substring(@sSql2,6,len(@sSql2)-7),' ','' )              
                  
                  -- add closing paren
                  set @sSql = @sSql+@sSql2+'); '
                  set @msg = cast(GetDate() as varchar) + ': ' + @sSql
                  exec absp_Util_LogIt @msg, 1, 'absp_Migr_CheckIndex'
                  execute(@sSql)
               end
            end
         end
      end
      fetch next from cursDictidx into @cursDictidx_indxName,@cursDictidx_tblName
   end
   close cursDictidx
   deallocate cursDictidx
   -- end of the table/index cursor
   
   if (@retCode > 0)
   begin
      set @msg = cast(GetDate() as varchar(max))+' indicies!'
      exec absp_Util_LogIt @msg, 1, 'absp_Migr_CheckIndex'
   end
   else
   begin
      set @msg = cast(GetDate() as varchar) + ': absp_Migr_CheckIndex - Success!'
      exec absp_Util_LogIt @msg, 1, 'absp_Migr_CheckIndex'
   end
   return @retCode
end
