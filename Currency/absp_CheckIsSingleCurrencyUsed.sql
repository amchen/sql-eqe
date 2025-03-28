if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CheckIsSingleCurrencyUsed') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_CheckIsSingleCurrencyUsed
end

go
create procedure absp_CheckIsSingleCurrencyUsed @ret_table_name char(120) output ,
                                                @node_key int,
                                                @node_type int,
                                                @extraDebug int = 0,
                                                @targetDB varchar(130)=''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates a custom table that contains the list of all the programs. The primary objective
of this procedure is to check if the policy/site data of a given program uses single currency code or node.
Based on the node_key and node_type the list of programs can be a single program, all programs under a 
Reinsurance, all programs under all Reinsurance portfolio that are child of a a given Acccumulation.

This procedure returns the table name back and the table is used later by absp_TreeviewProgramPartsClone
to fill in the TARGET_PROG_KEY and the same table is passed to CurrConvR engine that uses the information 
from these table to copy blob data.

The table is dropped from the Java Server after copy-paste operation is completed.
This procedure is very specific for copy-paste of Intermediate results across currency folder. 

Returns:       Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @node_key ^^  The key of the node.  
##PD  @node_type ^^  The node type. Applicable node types are APORT (1), RPORT (3), RAPORT (23), Program (7), Account(27).
##PD  @ret_table_name ^^ The name of the table created by this procedure.
##PD  @extraDebug ^^ If this flag is set to 1 then the procedure calculates the time taken to process each Program or Account,
it also calculates the records processed per sec. By default this flag should be set to 0.



*/
as
begin
 
   set nocount on
   
  declare @sql varchar(max)
   declare @table_name2 varchar(max)
   declare @tables_list char(1024)
   declare @tempsql varchar(1024)
   declare @nsql nvarchar(max)
   declare @tmpTargetDb varchar(128)
   
   create table #PROG_TO_CHECK
   (
      PROG_KEY INT   null
   )
   create table #TABLES_TO_CHECK
   (
      TABLE_NAME CHAR(20)  COLLATE SQL_Latin1_General_CP1_CI_AS null,
      FIELD_NAME CHAR(20)  COLLATE SQL_Latin1_General_CP1_CI_AS  null -- This is the main table. The procedure will populate this table and return the table name.
   )

   if @targetDB=''
      set @targetDB = DB_NAME()
   
   if charindex('[',dbo.trim(@targetDB)) = 0
   	set @tmpTargetDb = @targetDB
   else
   begin
   	set @tmpTargetDb = left(dbo.trim(@targetDB), len(dbo.trim(@targetDB)) - (CHARINDEX(']', REVERSE(dbo.trim(@targetDB)))))
   	set @tmpTargetDb = RIGHT(dbo.trim(@tmpTargetDb), len(dbo.trim(@tmpTargetDb)) -1 )
   end
      
   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB


    set @nsql='execute ' + dbo.trim(@targetDB) + '..absp_Util_MakeCustomTmpTable @table_name2 out ,''TMP_PROG_LIST'',''SRC_PROG_KEY int, TARGET_PROG_KEY int, IS_CURR_MISMATCH char(1), CURR_CODE char(3), CURR_RATIO float (53), STATUS char(1), TOTAL_TIME char(20), TOTAL_RECORDS int, REC_PER_SEC int, SOURCEDBNAME varchar(128), TARGETDBNAME varchar(128)'''
    print @nSql
    execute sp_executesql @nsql,N'@table_name2 varchar(max) output',@table_name2 output

   
   set @ret_table_name = @table_name2
end


