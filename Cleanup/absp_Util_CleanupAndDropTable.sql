if exists(select * from sysobjects where id = object_id(N'absp_Util_CleanupAndDropTable') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CleanupAndDropTable
end

go
create  procedure /*

This procedure will cleanup a given table based on the number of 
records to delete. The default numRowsToDelete is -1 and all records
will be deleted if this argument is not set. If the table is empty 
then the table will be dropped.

SDG__00012437 and SDG__00013183.  Slowly delete records and finally table named in DELETEME table.
*/
absp_Util_CleanupAndDropTable @theTableToDelete char(100),@numRowsToDelete int = -1,@debugFlag INT = 0 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure will cleanup a given table based on the number of 
records to delete. The default numRowsToDelete is -1 and all records
will be deleted if this argument is not set. If the table is empty 
then the table will be dropped.


Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  @theTableToDelete ^^  Table namefrom which records have to be deleted. 
##PD  @numRowsToDelete 	^^  No. of records to be deleted. 
##PD  @debugFlag	^^  Whether to debug with any message (> 0 to debug)		

*/
as
begin

   set nocount on
   
  -- standard declares
   -- Procedure Name
   -- for messaging
   declare @me varchar(max)
   declare @debug int -- to handle sql type work
  -- put other variables here
   declare @msg varchar(max)
   declare @sql nvarchar(4000)
   declare @isEmpty int
   declare @bExists int
   declare @theTable char(100)
   declare @msgText varchar(255)
  -- initialize standard items
   set @me = 'absp_Util_CleanupAndDropTable: ' -- set to my name Procedure Name
   set @debug = @debugFlag
   set @theTable = rtrim(ltrim(@theTableToDelete))
   set @msg = @me+'starting'+' @tableName = '+@theTable+' numRowsToDelete = '+rtrim(ltrim(str(@numRowsToDelete)))
   set @sql = ''
  -- intialize other variables here
   set @isEmpty = 1
   set @bExists = 0
  -------------- start --------------------	
   if @debug > 0
   begin
      execute absp_messageEx @msg
   end
  -- check if the table exists or not
   set @sql = 'select @bExists = 1 from SYS.TABLES where NAME = '''+@theTable+''''
   execute sp_executesql @sql,N'@bExists int output',@bExists output

    set @bExists = isnull(@bExists,0)
  -- delete the table entry from DELETEME table
   if(@bExists = 0)
   begin
      set @sql = 'delete DELETEME where TABLENAME = '''+@theTable+''''
      if @debug > 0
      begin
         execute absp_messageEx @sql
      end
      execute(@sql)
    end
   else
   begin
    -- the table is not empty and still exists
      if(@numRowsToDelete < 1)
      begin
         set @sql = 'truncate table '+@theTable
      end
      else
      begin
         set @sql = 'delete top ('+cast(@numRowsToDelete as char)+') from '+@theTable
      end
      if @debug > 0
      begin
         execute absp_messageEx @sql
      end
      execute(@sql)
    --SDG__00013495 - replace checkpoint with a commit;
      -- Check if the table is empty
      set @sql = 'if exists ( select * from '+@theTable+' ) begin set @isEmpty=1 end else begin set @isEmpty=0 end '
      execute sp_executesql @sql,N'@isEmpty int output',@isEmpty output
      if @debug > 0
      begin
         execute absp_messageEx @sql
         set @msgText = 'Count '+str(@isEmpty)
         execute absp_messageEx @msgText
      end
    end
  -- if the table is empty, drop it and delete the entry from DELETEME
   if(@isEmpty = 0)
   begin
      set @sql = 'drop table '+@theTable
      if @debug > 0
      begin
         execute absp_messageEx @sql
      end
      execute(@sql)
      set @sql = 'delete DELETEME where TABLENAME = '''+@theTable+''''
      if @debug > 0
      begin
         execute absp_messageEx @sql
      end
      execute(@sql)
    end
  -------------- end --------------------
   if @debug > 0
   begin
      set @msg = @me+'complete'
      execute absp_messageEx @msg
   end
 end


