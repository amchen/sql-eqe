
if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewCaseClone') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewCaseClone
end
go

create procedure absp_TreeviewCaseClone @caseKey int,
                                        @newProgKey int,
                                        @createDate char(120),
                                        @createBy int,
                                        @bcaseOnlyFlag int,
                                        @resultsFlag int,
                                        @targetDB varchar(130)=''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure:
- Clones a case, its user notes and all its parts and attaches it to a new parent program.
- If the new parent program has no base case, the new cloned case is made the base case.
- If the parent program has a case with the same name,a new case name is given.
- Returns the new case key


Returns:      A single value @lastKey
@lastKey > 0   If the clone case is created (It returns the key of the created case)
@lastKey = 0   If the clone case is not created


====================================================================================================
</pre>
</font>
##BD_END

##PD  @caseKey ^^  The key of the case that is to be cloned. 
##PD  @newProgKey ^^  The key of the program to which the clone case is to be attached.
##PD  @createDate ^^  Unused parameter. 
##PD  @createBy ^^  Unused parameter.
##PD  @bcaseOnlyFlag ^^  Unused parameter
##PD  @resultsFlag ^^  Unused parameter

##RD @lastKey ^^  The key of the new clone case.

*/
as
begin
  -- this procedure will clone a Case to a new parent by adding the
  -- new item itself
  
   set nocount on
  
   declare @lastKey int
   declare @baseCaseKey int
   declare @longName char(120)
   declare @newName char(120)
   --multi-Treaty
   declare @tmpName char(120)
   declare @tabSep char(2)
   declare @prog_node_type int
   declare @whereClause  varchar(1000)
   declare @fieldValueTrios  varchar(max)
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
		
   
   -- Fixed Defect: M1103
   -- Need to call absp_Util_GetProgramType on the target database
   set @sql = 'exec @prog_node_type =  ' + dbo.Trim(@targetDB) + '..absp_Util_GetProgramType '  + cast(@newProgKey as char)
   
   
   execute sp_executesql @sql, N'@prog_node_type int output',@prog_node_type output
   
   execute  absp_GenericTableCloneSeparator @tabSep output
   
   -- get the existing info
   select   @longName = LONGNAME from CASEINFO where CASE_KEY = @caseKey
   
   -- now see if we can get a new name
   -- we only need this if the parent Program has the same thing
   set @sql='select @tmpName = LONGNAME from ' + dbo.trim(@targetDB) + '..CASEINFO 
                        where PROG_KEY = ' + dbo.trim(str(@newProgKey)) + ' and LONGNAME = ''' + dbo.trim(@longName) + ''''
   execute sp_executesql @sql,N'@tmpName char(120) output',@tmpName output

   
   if @tmpName = @longName
   begin
      set @sql = 'execute  ' + dbo.Trim(@targetDB) + '..absp_GetUniqueName @newName output,''' + @longName +''',''CASEINFO'',''LONGNAME'''
      execute sp_executesql @sql,N'@newName char(120) output',@newName output
   end
   else
   begin
      set @newName = @longName
   end
   -- copy into a new one with the new unique name
   set @whereClause = ' CASE_KEY = '+cast(@caseKey as char)
   set @fieldValueTrios = 'str'+@tabSep+'LONGNAME'+@tabSep+@newName+@tabSep+'int'+@tabSep+'PROG_KEY'+@tabSep+cast(@newProgKey as char)
   execute @lastKey = absp_GenericTableCloneRecords 'CASEINFO',1,@whereClause,@fieldValueTrios,0,@targetDB
   
   -- update any notes
   execute absp_UserNotesClone 3,@caseKey,@lastKey,@targetDB
   
   -- update the parts that depend on case key
   execute absp_TreeviewCasePartsClone @caseKey,@lastKey,@targetDB
   
   -- only update basecase key when the program is a single-Treaty node 
   if @prog_node_type = 7
   begin
    -- by any chance does the Program have no Base Case"?"
      set @sql = 'select   @baseCaseKey = BCASE_KEY from ' + dbo.trim(@targetDB) + '..PROGINFO where PROG_KEY = ' + cast(@newProgKey as varchar)
      execute sp_executesql @sql,N'@baseCaseKey int output',@baseCaseKey output
      
      if @baseCaseKey = 0
      begin
         set @sql = 'begin transaction; update ' + dbo.trim(@targetDB) + '..PROGINFO set BCASE_KEY = ' + str(@lastKey) + ' where PROG_KEY = ' + str(@newProgKey)+'; commit transaction; '
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
end