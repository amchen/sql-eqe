
if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewPPortfolioClone') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewPPortfolioClone
end
go

create procedure absp_TreeviewPPortfolioClone
	@pportKey int,
	@newParentKey int,
	@newParentType int,
	@oldParentKey int,
	@oldParentType int,
	@createBy int,
	@fromAPORTClone int = 0,
	@targetDB varchar(130)=''

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure clones a Pport,user notes,the corresponding lports,log information and attaches it
to a given parent node.


Returns:       A single value @lastKey
@lastKey >0   If the clone pport is created (It returns the key of the created pport)
@lastKey=0    If the clone pport is not created

====================================================================================================
</pre>
</font>
##BD_END

##PD  @pportKey ^^  The key of the pport that is to be cloned.
##PD  @newParentKey ^^  The key of the parent to which the cloned pport is to be attached.
##PD  @newParentType ^^  The node type of the parent to which the cloned pport will be attached.
##PD  @oldParentKey ^^  The key of the parent to which the given pport is attached.
##PD  @oldParentType ^^  The node type of the parent to which given pport is attached.
##PD  @createBy ^^  The user key of the user creating the clone.
##PD  @fromAPORTClone ^^  An integer value.

##RD @lastKey ^^  the key of the new pport.
*/

as

BEGIN TRY

	set nocount on

	-- this procedure will clone an PPortfolio to a new parent by first adding the
	-- new item itself and then adding the map entry
   declare @PARAM3 varchar(4000)
   declare @PARAM4 varchar(4000)
   declare @lastKey int
   declare @longName char(120)
   declare @newName char(120)
   declare @tabSep char(2)
   declare @newLportKey int
   declare @toCurrencyNodeKey int
   declare @fromCurrencyNodeKey int
   declare @curs_LportKey int
   declare @sql nvarchar(max)
   declare @createdLookups int

   set @createdLookups =0

   if @targetDB=''
   	set @targetDB = DB_NAME()

   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB

   --Find new lookups if different CFDB
   if  substring(@targetDB,2,len(@targetdb)-2)<>DB_NAME()
	exec @createdLookups=absp_FindNewDynamicLookups @targetDB

   execute absp_GenericTableCloneSeparator @tabSep output
  -- get the existing info
   select  @longName = LONGNAME  from PPRTINFO where PPORT_KEY = @pportKey
   If (@longName is null) set @longName = ' '

   -- now see if we can get a new name
   set @sql = 'execute  ' + dbo.Trim(@targetDB) + '..absp_GetUniqueName @newName output,''' + @longName +''',''PPRTINFO'',''LONGNAME'''
   execute sp_executesql @sql,N'@newName char(120) output',@newName output

   If (@newName is null) set @newName = ' '

  set @PARAM3 = ' PPORT_KEY = '+cast(@pportKey as char)
  set @PARAM4 = 'STR '+@tabSep+'LONGNAME'+@tabSep+@newName

  execute @lastKey = absp_GenericTableCloneRecords 'PPRTINFO',1,@PARAM3,@PARAM4, 0,@targetDB
  
    -- copy into a new one with the new unique name
   set @PARAM3 = ' NodeKey = '+cast(@pportKey as char) + ' and NodeType = 2'
   set @PARAM4 = 'INT '+@tabSep+'NodeKey'+@tabSep+cast(@lastKey as varchar(30))

  execute dbo.absp_GenericTableCloneRecords 'ExposureDataFilterInfo',1,@PARAM3,@PARAM4, 0,@targetDB 
  execute dbo.absp_GenericTableCloneRecords 'ExposureDataSortInfo',1,@PARAM3,@PARAM4, 0,@targetDB 


  -- update the map
   if @newParentType = 0
   begin
   	  set @sql='begin transaction; insert into ' + dbo.trim(@targetDB) + '..FLDRMAP(FOLDER_KEY,CHILD_KEY,CHILD_TYPE)
                       values(' + cast(@newParentKey as varchar) +','+ cast(@lastKey as varchar) + ',2); commit transaction; '

      execute(@sql)

   end
   else if @newParentType = 1
   begin
   	   set @sql=' begin transaction; insert into ' + dbo.trim(@targetDB) + '..APORTMAP(APORT_KEY,CHILD_KEY,CHILD_TYPE)
                       values(' + cast(@newParentKey as varchar) +','+ cast(@lastKey as varchar) + ',2); commit transaction; '
       execute(@sql);
   end

   -- update any notes
   execute absp_UserNotesClone 4,@pportKey,@lastKey, @targetDB
   -- now clone all real portfolios  belonging to me

   --Clone ExposureSets
   exec absp_TreeviewExposureClone 2,@pportKey,2,@lastKey,@targetDB, -999, 1
   
   --Set Status to Imported -- Fixed defect 7054
   --set @sql='update ' +  dbo.trim(@targetDB) + '..ExposureInfo set  Status = ''Imported'' 
   --from ' +  dbo.trim(@targetDB) + '..ExposureInfo A inner join ' +  dbo.trim(@targetDB) + '..ExposureMap B
   --on A.ExposureKey=B.ExposureKey
   --where B.ParentKey= ' + cast(@lastKey as varchar(30)) + ' and B.ParentType=2 and Status = ''Copying'' '
   --execute(@sql);

   /*-- SDG__00015383 -- Copy of Primary Portfolio does not copy the Version Information in EXPDONE
   set @sql='insert into '+ dbo.trim(@targetDB) + '..EXPDONE
               (PPORT_KEY,PROG_KEY,FINISH_DAT,SUMMARY,BY_GEO,BY_STRUCT,BY_QF,WCEVERSION, FL_CERTVER)
             select  ' + str(@lastKey) + ',PROG_KEY,FINISH_DAT,SUMMARY,BY_GEO,BY_STRUCT,BY_QF,WCEVERSION,
                 FL_CERTVER from EXPDONE where PPORT_KEY = ' + str(@pportKey)
   execute(@sql)*/
   
   -- delete the reference rprt_key if we move the portfolio to a different currency node
   -- if the portfolio is moved to different currency node then we need to set the REF_PPTKEY to 0.
   execute @fromCurrencyNodeKey = absp_FindNodeCurrencyKey @oldParentKey,@oldParentType
   execute @toCurrencyNodeKey = absp_FindNodeCurrencyKey @newParentKey,@newParentType
   if @fromCurrencyNodeKey <> @toCurrencyNodeKey
   begin
      set @sql='begin transaction; update ' + dbo.trim(@targetDB) + '..PPRTINFO set ref_pptkey = 0  where ref_pptkey = ' +str(@lastKey)+'; commit transaction; '
      execute(@sql)
      
      set @sql='begin transaction; update ' + dbo.trim(@targetDB) + '..PPRTINFO set ref_pptkey = 0  where PPORT_KEY = ' +str(@lastKey)+'; commit transaction; '
      execute(@sql)
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
