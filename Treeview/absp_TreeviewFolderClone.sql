
if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewFolderClone') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewFolderClone
end
 go
create procedure absp_TreeviewFolderClone @folderKey int,
										  @newParentKey int,
										  @createBy int,
										  @targetDB varchar(130)=''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates a clone of given folder node, its user notes and all its children and attaches it to the 
specified parent folder node. 


Returns:       A single value @lastKey
@lastKey >0   If the clone folder is created (It returns the key of the created node)
@lastKey=0    If the clone folder is not created
====================================================================================================
</pre>
</font>
##BD_END

##PD  @folderKey ^^  The key of the folder that is to be cloned. 
##PD  @newParentKey ^^  The key of the parent folder to which the clone is to be attached
##PD  @createBy ^^  The key of the user creating the clone

##RD @lastKey ^^  The key of the new clone folder node.

*/
AS

begin
  
  set nocount on
  
  -- this procedure will clone an Folder to a new parent by first adding the
  -- new item itself, cloning all children, and then adding the map entry
   declare @lastKey int
   declare @longName char(120)
   declare @newName char(120)
   declare @tabSep char(2)
   declare @whereClause varchar(max)
   declare @folderkeyTrio varchar(max)
   declare @curs1_ChildKey int
   declare @curs1_ChildType smallint
   declare @sql nvarchar(4000)
   declare @createdLookups int
      
   set @createdLookups =0
   
   if @targetDB=''
   	set @targetDB = DB_NAME()
   	
   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB

    --Find new lookups if different CFDB
    if substring(@targetDB,2,len(@targetdb)-2)<>DB_NAME()
		exec @createdLookups=absp_FindNewDynamicLookups @targetDB

   execute  absp_GenericTableCloneSeparator @tabSep output
   -- message 'absp_TreeviewFolderClone(folderKey=',folderKey,', newParentKey=',newParentKey,')';
   if @folderKey = 0
   begin
      set @lastKey = 0
      return @lastKey
   end
   
  -- get the existing info
   select  @longName = LONGNAME from FLDRINFO where FOLDER_KEY = @folderKey
   
   If (@longName is Null) Set @longName =''
  
	-- now see if we can get a new name
   set @sql = 'execute  ' + dbo.Trim(@targetDB) + '..absp_GetUniqueName @newName output,''' + @longName +''',''FLDRINFO'',''LONGNAME'''
   execute sp_executesql @sql,N'@newName char(120) output',@newName output
      
   If (@newName is Null) Set @newName =''
   
  -- copy into a new one with the new unique name
   set @whereClause = ' FOLDER_KEY = '+cast(@folderKey as char)
   set @folderkeyTrio = 'STR '+@tabSep+'LONGNAME'+@tabSep+@newName
   execute @lastKey = absp_GenericTableCloneRecords 'FLDRINFO',1,@whereClause,@folderkeyTrio,0,@targetDB
   
  -- SDG__00015472 -- CURRMAP is populated with a folder_key of -1 and user is unable to 
  --                  create a reference to porfolios under a copied folder
  -- In absp_TreeviewFolderClone, it was cloneing the children 
  -- and then adding the new folder to the FLDRMAP.   
  -- This made the trigger, insert_of_CURRMAP_for_FLDRMAP AFTER INSERT ON FLDRMAP not have 
  -- the ability to find the currencyNode.   
  -- Fix by inserting the FLDRMAP record first and then cloning the children.
 
  set @sql = 'begin transaction; insert into ' + dbo.trim(@targetDB) + '..FLDRMAP
                    (FOLDER_KEY,CHILD_KEY,CHILD_TYPE) values(' + cast(@newParentKey as varchar) +',' + cast(@lastKey as varchar) + ',0); commit transaction; '
  execute (@sql)
   -- clone all children
  
    -- message '  absp_TreeviewGenericNodeClone(CHILD_KEY=',CHILD_KEY,', CHILD_TYPE=',CHILD_TYPE,', @lastKey=',@lastKey,',0, folderKey=',folderKey,',0)';
    -- generic node does a commit, so each level is consistent
   declare curs1  cursor local for 
      select  CHILD_KEY,CHILD_TYPE from FLDRMAP where FOLDER_KEY = @folderKey
   open curs1
   fetch next from curs1 into @curs1_ChildKey,@curs1_ChildType
   while @@fetch_status = 0
   begin
      execute absp_TreeviewGenericNodeClone @curs1_ChildKey,@curs1_ChildType,@lastKey,0,@folderKey,0,@createBy,0,'',0,@targetDB
      fetch next from curs1 into @curs1_ChildKey,@curs1_ChildType
   end
   close curs1
   deallocate curs1
  -- update any notes
   execute absp_UserNotesClone 7,@folderKey,@lastKey,@targetDB
   
   --If lookups are created, drop temp tables
   if @createdLookups = 1
   begin
   	 exec absp_DropTmpLookupTables
   	 if exists (Select 1 from tempdb.INFORMATION_SCHEMA.Tables Where Table_name='##TMP_LKUPCLONE_STATUS')
   	 	delete from ##TMP_LKUPCLONE_STATUS  where DBNAME=@targetDB AND SP_ID =@@SPID 
   end
   
   return @lastKey
end