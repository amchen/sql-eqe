
if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewRPortfolioClone') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewRPortfolioClone
end
 go
create procedure absp_TreeviewRPortfolioClone @rportKey int,
                                              @newParentKey int,
                                              @newParentType int,
                                              @oldParentKey int,
                                              @oldParentType int,
                                              @createBy int,
                                              @recursiveFlag int,
                                              @resultsFlag int,
                                              @bcaseOnlyFlag int,
                                              @portinfoFlag int, 
                                              @temp_prog_table char(1000) = '',
                                              @fromAPORTClone int = 0,
                                              @targetDB varchar(130)
                                              
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure clones an Rport,user notes,the child programs and attaches it
to a given parent node.


Returns:       A single value @lastKey
@lastKey >0   If the clone rport is created (It returns the key of the created rport)
@lastKey=0    If the clone rport is not created

====================================================================================================
</pre>
</font>
##BD_END

##PD  @rportKey ^^  The key of the rport that is to be cloned. 
##PD  @newParentKey ^^  The key of the parent to which the cloned rport is to be attached.
##PD  @newParentType ^^  The node type of the parent to which the cloned rport will be attached.
##PD  @oldParentKey ^^  The key of the parent to which the given rport is attached.
##PD  @oldParentType ^^  The node type of the parent to which given rport is attached.
##PD  @createBy ^^  The user key of the user creating the clone. 
##PD  @recursiveFlag ^^  A flag used to indicate whether the child programs are to be cloned.
##PD  @resultsFlag ^^  A flag used by absp_TreeviewProgramClone to indicate whether the intermediate results are to be cloned.
##PD  @bcaseOnlyFlag ^^  A flag used by absp_TreeviewProgramClone to indicate if only the base case is to be cloned.
##PD  @portinfoFlag ^^  A flag used by absp_TreeviewProgramClone to indicate if the port information are to be cloned.

##RD @lastKey ^^  The key of the new rport.

*/
as

BEGIN TRY
  -- this procedure will clone an RPortfolio to a new parent by first adding the
  -- new item itself and then adding the map entry
  
   set nocount on  
   
   declare @lastKey int
   declare @longName varchar(2000)
   declare @newName varchar(2000)
   declare @tabSep char(10)
   declare @fromCurrencyNodeKey int
   declare @toCurrencyNodeKey int
   declare @rport_node_type int   
   declare @whereClause varchar(max)
   declare @newFldValueTrios varchar(max)
   declare @curs_ProgKey int
   declare @sql nvarchar(max)
   declare @createdLookups int
      
   set @createdLookups =0
   
   if @targetDB=''
   	set @targetDB = DB_NAME()
   	
   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB

    --Find new lookups if different CFDB
    if substring(@targetDB,2,len(@targetdb)-2)<>DB_NAME()
		exec @createdLookups=absp_FindNewDynamicLookups @targetDB
		
   execute @rport_node_type = absp_Util_GetRPortType @rportKey
   
   execute  absp_GenericTableCloneSeparator @tabSep output
   
   -- get the existing info
   select   @longName = LONGNAME from RPRTINFO where RPORT_KEY = @rportKey
   if (@longName is null) set @longName =''
     
   	-- now see if we can get a new name
    set @sql = 'execute  ' + dbo.Trim(@targetDB) + '..absp_GetUniqueName @newName output,''' + @longName +''',''RPRTINFO'',''LONGNAME'''
    execute sp_executesql @sql,N'@newName char(120) output',@newName output
   
    if (@newName is Null) Set @newName =''
  
  -- copy into a new one with the new unique name
   set @whereClause = ' RPORT_KEY = '+cast(@rportKey as char)
   set @newFldValueTrios = 'STR '+@tabSep+'LONGNAME'+@tabSep+@newName
--	begin transaction; 
		execute @lastKey = absp_GenericTableCloneRecords 'RPRTINFO',1,@whereClause,@newFldValueTrios,0,@targetDB
--	commit transaction; 
  -- update any notes
   execute absp_UserNotesClone 1,@rportKey,@lastKey,@targetDB
   
  -- see if we do children
   if @recursiveFlag = 1
   begin
    -- now clone children by getting list of all people belonging to me
      declare cursRprt cursor fast_forward for select CHILD_KEY as PROG_KEY from RPORTMAP where
                                                 RPORT_KEY = @rportKey and(CHILD_TYPE = 7 or CHILD_TYPE = 27)
      open cursRprt
      fetch next from cursRprt into @curs_ProgKey
      while @@fetch_status = 0
      begin
         execute absp_TreeviewProgramClone @curs_ProgKey,@lastKey,@createBy,@recursiveFlag,@resultsFlag,@bcaseOnlyFlag,@portinfoFlag,@temp_prog_table,@targetDB
         fetch next from cursRprt into @curs_ProgKey
      end
      close cursRprt
      deallocate cursRprt
   end
  -- Check if  the portfolio is coppied under diffent currency node then reset the reference portfolio key to 0.
    --execute @fromCurrencyNodeKey = absp_FindNodeCurrencyKey @oldParentKey,@oldParentType
    --execute @toCurrencyNodeKey = absp_FindNodeCurrencyKey @newParentKey,@newParentType
   
   if dbo.trim(@targetDB) <> DB_NAME()
   begin
      
      set @sql = 'begin transaction; update ' + dbo.trim(@targetDB) + '..RPRTINFO set REF_RPTKEY = 0  where REF_RPTKEY = ' + str(@lastKey)+'; commit transaction; '
      execute(@sql)
      
      set @sql = 'begin transaction; update ' + dbo.trim(@targetDB) + '..RPRTINFO set REF_RPTKEY = 0  where RPORT_KEY = ' + str(@lastKey)+'; commit transaction; '
      execute(@sql)
   end
  -- Finally add the node to the tree
  
    -- update the map
    
    -- update the map
   if @newParentType = 0
   begin
      set @sql = 'begin transaction; insert into ' + dbo.trim(@targetDB) + '..FLDRMAP(FOLDER_KEY,CHILD_KEY,CHILD_TYPE) 
                     values(' + str(@newParentKey) + ',' + str(@lastKey) + ',' + str(@rport_node_type) + '); commit transaction; '
      execute(@sql)
   end
   else
   begin
      if @newParentType = 1
      begin
         set @sql = 'begin transaction; insert into  ' + dbo.trim(@targetDB) + '..APORTMAP(APORT_KEY,CHILD_KEY,CHILD_TYPE) 
                      values(' + str(@newParentKey) + ',' + str(@lastKey) + ',' + str(@rport_node_type) + '); commit transaction; '
          execute(@sql)
      end
   end
   
   --If lookups are created, drop temp tables
   if @createdLookups = 1
   begin
   	 exec absp_DropTmpLookupTables
   	 if exists (Select 1 from tempdb.INFORMATION_SCHEMA.Tables Where Table_name='##TMP_LKUPCLONE_STATUS')
   	 	delete from ##TMP_LKUPCLONE_STATUS  where DBNAME=@targetDB AND SP_ID =@@SPID 
 
   end
   return @lastKey
END TRY 
BEGIN CATCH
	declare @ProcName varchar(100)
	select @ProcName=object_name(@@procid)
	exec absp_Util_GetErrorInfo @ProcName
END CATCH