if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_MakeCustomTmpTable') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_MakeCustomTmpTable
end
 go
create procedure -------------------------------------------------------------
absp_Util_MakeCustomTmpTable @ret_TmpTableName varchar(max) output ,@tableToMakeBaseName varchar(120),@customCols varchar(MAX) = '',@tmpPostfix char(10) = '_TMP' 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates a temporary table and returns the name of the table.


Returns: Nothing 



====================================================================================================
</pre>
</font>
##BD_END 

##PD  @ret_TmpTableName ^^ An Output parameter which will hold the name of the table
##PD  @tableToMakeBaseName ^^  Any table name.
##PD  @customCols  ^^ a string containing the column names and the corresponding data type.
##PD  @tmpPostfix ^^ the postfix of the temp table.

*/
as
begin

   set nocount on
   
  /*
  This will create a unique temp table from tableToMake and customCols and return the temp table name:
  1) see if a tmp table exists; if so, 
  a) append random number and try 200 times to make a new one
  b) fail and return '' at 200+
  2) create the tmp table
  3) return the name we created
  */
   declare @sSql varchar(MAX)
   declare @tmpTablename varchar(120)
   declare @tmpTablename2 varchar(120)
   declare @i int
   declare @retCode int
   set @sSql = ''
   set @tmpTablename = rtrim(ltrim(@tableToMakeBaseName))+rtrim(ltrim(@tmpPostfix))
  -- just in case he tries to create his own table, do not let him
   if rtrim(ltrim(@tmpTablename)) = rtrim(ltrim(@tableToMakeBaseName))
   begin
      set @tmpTablename = ltrim(rtrim(@tmpTablename))+'_TMP'
   end
   set @i = 0
  -- SDG__00012941
   set @tmpTablename2 = ltrim(rtrim(@tmpTablename)) + rtrim(ltrim(str(7559*rand())))
   retryLoop: while 1 = 1
   begin
    -- create SQL statement
      set @sSql = 'create table '+@tmpTablename2+' ( '+@customCols+' ); '
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
         set @tmpTablename2 = ltrim(rtrim(@tmpTablename))+rtrim(ltrim(str(7559*rand()))) -- 7559 is a prime
         set @i = @i+1
         if @i > 200
         begin
            set @ret_TmpTableName = ''
            return
         end
      end
   end
  
   set @ret_TmpTableName = rtrim(ltrim(@tmpTablename2))
end




