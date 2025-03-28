if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_DropTempTables') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_DropTempTables
end

go

create procedure /*

Generic procedure to drop a list of tables. This procedure is used to drop temporary 
tables based on a given list.

TmpTableList -- List of tables to be deleted. The table name may contain '--' in that
case all tables that matches the table will be deleted.

Fixed Defect: SDG 12364. 12366

We will use '$' as the escape sequence. If we use this procedure to drop any 
table make sure the tablename is not containing '$'.
*/
/*
SDG__00012449 -- Add 'escape $' to each of the where clauses, one per table.
*/
absp_Util_DropTempTables @TmpTableList varchar(max),@debugFlag int = 0 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure drops a list of temporary tables enlisted in SYSTABLE.

Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  @TmpTableList 	^^  Temporary Table List to be deleted
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
   declare @msg varchar(max)
   declare @sql varchar(max)
   declare @tableName char(256)
   declare @whereClause varchar(max)
   declare @startIndx int
   declare @endIndx int
   declare @SWV_func_ABSP_MESSAGEEX_par01 varchar(max)
  -- initialize standard items
   set @me = 'absp_Util_DropTempTables: ' -- set to my name Procedure Name
   set @debug = @debugFlag -- initialize
   set @msg = @me+'starting'
   set @sql = ''
   set @tableName = ''
   set @whereClause = ''
   set @startIndx = 1
   set @endIndx = 1
   if @debug > 0
   begin
      execute absp_MessageEx @msg
      set @SWV_func_ABSP_MESSAGEEX_par01 = 'List of tables: '+@TmpTableList
      execute absp_MessageEx @SWV_func_ABSP_MESSAGEEX_par01
   end
  -- build the where clause; expected format (table_name like 'XX--' or table_name like 'YY--'....)
   select   @whereClause = replace(@TmpTableList,',',' <ESCAPE> or name like ') 
   select   @whereClause = replace(@whereClause,'<ESCAPE>',' escape ''$''') 
   set @whereClause = 'name like '+@whereClause+' escape ''$'''
   if @debug > 0
   begin
      execute absp_MessageEx @whereClause
   end
  -- Get all the temp table names that matches the list. The list may contain the temp table
  -- type (eg. 'BULKTMP_--' 
   set @sql = 'select name  from sys.tables where '+@whereClause
   if @debug > 0
   begin
      execute absp_MessageEx @sql
   end
   begin
    
      execute('declare curs1 cursor global for '+@sql)
      open curs1 
      fetch next from curs1 into @tableName
      while @@fetch_status =0
      begin
         if @debug > 0
         begin
            set @SWV_func_ABSP_MESSAGEEX_par01 = 'drop table '+@tableName
            execute absp_MessageEx @SWV_func_ABSP_MESSAGEEX_par01
         end
         execute('drop table '+@tableName)
		 fetch next from curs1 into @tableName 
      end
      close curs1
      deallocate curs1
   end

  -------------- end --------------------
   if @debug > 0
   begin
      set @msg = @me+'complete'
      execute absp_MessageEx @msg
   end
end



