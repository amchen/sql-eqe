if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_MakeTmpTable') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_MakeTmpTable
end
 go
 
create procedure -------------------------------------------------------------
absp_Util_MakeTmpTable @ret_TmpTableName varchar(1000) output ,@tableToMakeBaseName varchar(1000),@tmpPrefix varchar(100) = '',@tmpPostfix varchar(100) = '_TMP',@forceDropFlag int = 0,@dbSpaceName varchar(100) = '',@makeIndex bit = 0,@addDfltVal int = 0 
--returns char ( 70 )
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates a temporary table with the same structure as the existing base table and returns 
the temporary table name in a output parameter. If it fails to create the temporary table it will return 
a blank string.

Returns: Nothing.


====================================================================================================
</pre>
</font>
##BD_END 

##PD  @ret_TmpTableName ^^ The name of the temporary table created. This is an OUTPUT parameter
##PD  @tableToMakeBaseName ^^  The name of the base table
##PD  @tmpPrefix ^^ The prefix for the temp table.
##PD  @tmpPostfix ^^ The postfix for the temp table.
##PD  @forceDropFlag ^^ A flag to signify if the temporary table is to be deleted or not(default set to 0). 
##PD  @dbSpaceName ^^ The DB space name.
##PD  @makeIndex ^^ A flag which indicates if the indexes are to be created.
##PD  @addDfltVal ^^ A flag which indicates if the temporary table will have an autoincrement key field.


*/
as
begin
 
   set nocount on
   
 /*
  This will create a temp table from tableToMake and return the temp table name:
  1) see if a tmp table exists; if so, 
  a) delete it if force flag set
  b) append random number and try 100 times to make a new one
  c) fail and return '' at 100+
  2) create a tmp table
  3) return the name we created
  */
   declare @sSql varchar(max)
   declare @tmpTablename varchar(100)
   declare @tmpTablename2 varchar(100)
   declare @i int
   declare @retCode int
   set @sSql = ''
  --message 'inside absp_Util_MakeTmpTable, base table name = ' + tableToMakeBaseName;
  --message 'prefix = ' + tmpPrefix;
  --message 'postfix = ' + tmpPostfix;
   set @tmpTablename = rtrim(ltrim(@tmpPrefix))+rtrim(ltrim(@tableToMakeBaseName))+rtrim(ltrim(@tmpPostfix))
  -- just in case he tries to create his own table, do not let him
   if rtrim(ltrim(@tmpTablename)) = rtrim(ltrim(@tableToMakeBaseName))
   begin
      set @tmpTablename = @tmpTablename+'_TMP'
   end
   set @i = 0
  -- make sure we do not overwrite some existing table UNLESS you told me to!
  -- SDG__00012941
   set @tmpTablename2 = @tmpTablename
   
   if(select  count(*) from sys.tables where name = @tmpTablename2) > 0
   begin
    -- see if we should drop it or ignore it
      if @forceDropFlag = 1
      begin
         execute('drop table '+@tmpTablename2)
      end
      else
      begin
         if @forceDropFlag = 2
         begin
            set @ret_TmpTableName = @tmpTablename2
            return
         end
      end
   end
   retryLoop: while 1 = 1
   begin
    -- begin create SQL statement
      execute absp_Util_CreateTableScript @sSql output, @tableToMakeBaseName,@tmpTablename2,@dbSpaceName,@makeIndex,@addDfltVal
    -- execute create SQL statement and check for return value
      execute @retCode = absp_Util_SafeExecSQL @sSql,1
      if(@retCode = 0)
      begin
      -- success
         break
      end
      else
      begin
      -- failure, create a random appendage
         set @tmpTablename2 = rtrim(ltrim(@tmpTablename))+rtrim(ltrim(str(7559*rand()))) -- 7559 is a prime
         set @i = @i+1
         if @i > 200
         begin
            set @ret_TmpTableName = ''
            return
         end
      end
   end

set @ret_TmpTableName= @tmpTablename2;
end



