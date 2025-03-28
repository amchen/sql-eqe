
if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewProgramClone') and objectproperty(ID,N'isprocedure') = 1)
begin
	drop procedure absp_TreeviewProgramClone
end
go

create procedure absp_TreeviewProgramClone
	@progKey int,
	@newRPortKey int,
	@createBy int,
	@recursiveFlag int,
	@resultsFlag int,
	@bcaseOnlyFlag int,
	@portinfoFlag int,
	@temp_prog_table char(70) = '',
	@targetDB varchar(130)=''

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure clones a program,its parts,user notes,child cases, program logs,port information
for a given program key and returns the new program key.It creates a map to link it to the parent
rport.

Returns:       A single value @lastKey
@lastKey >0   If the clone program is created (It returns the key of the created program)
@lastKey=0    If the clone program is not created

====================================================================================================
</pre>
</font>
##BD_END

##PD  @progKey ^^  The key of the program which is to be cloned.
##PD  @newRPortKey ^^  The rport key that will the parent of the cloned program.
##PD  @createBy ^^  It is unused by this procedure and the called procedures.
##PD  @recursiveFlag ^^  A flag which indicates whether the children of the given program are to be cloned.
##PD  @resultsFlag ^^  A flag which indicates whether the intermediate results of program parts are to be cloned.
##PD  @bcaseOnlyFlag ^^  A flag which indicates whether all the child cases or just the base case is to be cloned.
##PD  @portinfoFlag ^^  A flag which indicates whether the port information of the program are to be cloned.
##PD  @temp_prog_table ^^  A temporary progrg table name which is passed in another procedure .

##RD  @lastKey ^^ The key of the new program.
*/

as

BEGIN TRY

  -- this procedure will clone a Program to a new parent by first adding the
  -- new item itself and then adding the map entry

   set nocount on

   declare @lastKey int
   declare @longName varchar(2000)
   declare @newName varchar(2000)
   declare @bCaseKey int
   declare @newCaseKey int
   declare @tabSep char(10)
   declare @createDate char(120)
   declare @where varchar(max)
   declare @substitutions varchar(max)
   declare @prog_node_type int
   declare @curs_CaseKey int
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

   execute @prog_node_type = absp_Util_GetProgramType @progKey

   -- now date
   exec absp_Util_GetDateString @createDate output,'yyyymmdd'
   execute  absp_GenericTableCloneSeparator @tabSep output

   -- get the existing info
   select   @longName = LONGNAME, @bCaseKey = BCASE_KEY  from PROGINFO where PROG_KEY = @progKey
   if (@longName is null) Set @longName=''

   -- now see if we can get a new name
   -- SDG__00011987 -- use absp_Util_SafeCloneInfoTable to retry if new name alreadyExist
   set @where = ' PROG_KEY = '+cast(@progKey as char)
   set @substitutions = 'STR'+@tabSep+' LONGNAME '+@tabSep -- note: SafeClone will append the @lastName

   execute @lastKey = absp_Util_SafeCloneInfoTable @longName,'PROGINFO','LONGNAME',1,@where,@substitutions,@targetDB

   -- update any notes
   execute absp_UserNotesClone 2,@progKey,@lastKey,@targetDB

   execute absp_TreeviewProgramPartsClone @progKey,@lastKey,@resultsFlag,@temp_prog_table,@targetDB

   -- do we do the children
   if @recursiveFlag = 1
   begin
    -- now clone children by getting list of all people belonging to me
      declare cursCaseInfo cursor fast_forward for select CASE_KEY from CASEINFO where PROG_KEY = @progKey
      open cursCaseInfo
      fetch next from cursCaseInfo into @curs_CaseKey
      while @@fetch_status = 0
      begin
         if @bcaseOnlyFlag = 1
         begin
            if @curs_CaseKey = @bCaseKey
            begin
               execute @newCaseKey = absp_TreeviewCaseClone @curs_CaseKey,@lastKey,@createDate,@createBy,@bcaseOnlyFlag,@resultsFlag,@targetDB
               --execute absp_BaseCaseSet @lastKey,@newCaseKey
	       set @sql = 'execute ' + dbo.trim(@targetDB) + '..absp_BaseCaseSet ' + str(@lastKey) + ', ' + str(@newCaseKey)
	       print @sql
               execute(@sql)
               break
            end
         end
         else
         begin
            execute @newCaseKey = absp_TreeviewCaseClone @curs_CaseKey,@lastKey,@createDate,@createBy,@bcaseOnlyFlag,@resultsFlag,@targetDB
            if @curs_CaseKey = @bCaseKey
            begin
               --execute absp_BaseCaseSet @lastKey,@newCaseKey
	       set @sql = 'execute ' + dbo.trim(@targetDB) + '..absp_BaseCaseSet ' + str(@lastKey) + ', ' + str(@newCaseKey)
	       print @sql
               execute(@sql)
            end
         end
         fetch next from cursCaseInfo into @curs_CaseKey
      end
      close cursCaseInfo
      deallocate cursCaseInfo
   end

  
  -- Finally add the node to the tree
  -- update the map
   set @sql = 'begin transaction; insert into ' + dbo.trim(@targetDB) + '..RPORTMAP(RPORT_KEY,CHILD_KEY,CHILD_TYPE)
                  values(' + str(@newRPortKey) + ',' + str(@lastKey) + ',' + str(@prog_node_type) + '); commit transaction; '
   execute absp_MessageEx @sql
   exec(@sql)
   
    --Clone ExposureSets
   exec absp_TreeviewExposureClone @prog_node_type,@progKey,@prog_node_type,@lastKey,@targetDB, -999, 1

	--Clone ExposureDataFilter and sort tables--
	set @where = ' NodeKey = '+cast(@progKey as char) + ' and NodeType = 27'
   set @substitutions = 'INT '+@tabSep+'NodeKey'+@tabSep+cast(@lastKey as varchar(30))

	execute dbo.absp_GenericTableCloneRecords 'ExposureDataFilterInfo',1,@where,@substitutions, 0,@targetDB 
	execute dbo.absp_GenericTableCloneRecords 'ExposureDataSortInfo',1,@where,@substitutions, 0,@targetDB 


   --Set Status to Imported -- Fixed defect 7054
   --set @sql='update ' +  dbo.trim(@targetDB) + '..ExposureInfo set  status = ''Imported'' 
   --from ' +  dbo.trim(@targetDB) + '..ExposureInfo A inner join ' +  dbo.trim(@targetDB) + '..ExposureMap B
   --on A.ExposureKey=B.ExposureKey
   --where B.ParentKey=' + cast(@lastKey as varchar(30)) + ' and B.ParentType=27 and Status = ''Copying'' '
   --execute(@sql);
   
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
