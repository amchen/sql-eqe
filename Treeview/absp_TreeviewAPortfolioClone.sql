
if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewAPortfolioClone') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewAPortfolioClone
end
 go
 
create procedure absp_TreeviewAPortfolioClone @aportKey int,
											  @newParentKey int,
											  @newParentType int,
											  @createBy int,
											  @results int = 0,
											  @temp_prog_table char(70) = '',
											  @targetDB varchar(130)=''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure 
- Clones an Aport,its parts, user notes and all its children and attaches it to a given parent node.
- Returns the key of the new aport


Returns:       A single value @lastKey
@lastKey >0   If the clone aport is created (It returns the key of the created aport)
@lastKey=0    If the clone aport is not created
====================================================================================================
</pre>
</font>
##BD_END

##PD  @aportKey ^^  The key of the aport that is to be cloned. 
##PD  @newParentKey ^^  The key of the parent to which the cloned aport is to be attached.
##PD  @newParentType ^^  The node type of the parent to which the cloned aport will be attached. 
##PD  @createBy ^^  The user key of the user creating the clone. 

##RD @lastKey ^^  The key of the new aport.

*/
as


begin
  -- this procedure will clone an APortfolio to a new parent by first adding the
  -- new item itself and then adding the map entry
  set nocount on
  
   declare @lastKey int
   declare @longName varchar(2000)
   declare @newName varchar(2000)
   declare @tabSep char(10)   
   declare @whereClaus varchar(max)
   declare @NewFldValueTrios varchar(max)
   declare @curs1_ChildKey int
   declare @curs1_ChildType smallint
   declare @curs1 cursor
   declare @sql nvarchar(max)
   declare @newKey int
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
   
   -- get the existing info
   select   @longName = LONGNAME from APRTINFO where APORT_KEY = @aportKey
   
   If (@longName is Null) Set @longName =''
  
   -- now see if we can get a new name
   set @sql = 'execute  ' + dbo.Trim(@targetDB) + '..absp_GetUniqueName @newName output,''' + @longName +''',''APRTINFO'',''LONGNAME'''
   execute sp_executesql @sql,N'@newName char(120) output',@newName output

   if (@newName is Null) Set @newName =''
      
  -- copy into a new one with the new unique name
   set @whereClaus = ' APORT_KEY = '+cast(@aportKey as CHAR)
   set @NewFldValueTrios = 'STR '+@tabSep+'LONGNAME'+@tabSep+@newName
   execute @lastKey = absp_GenericTableCloneRecords 'APRTINFO',1,@whereClaus,@NewFldValueTrios,0,@targetDB
  
    -- update the map
    
  -- SDG_00006848: take care of copying under a currency node

   if @newParentType = 0 or @newParentType = 12
   begin
      set @sql='begin transaction; insert into ' + dbo.trim(@targetDB) + '..FLDRMAP(FOLDER_KEY,CHILD_KEY,CHILD_TYPE) 
                    values(' + cast(@newParentKey as varchar) +','+ cast(@lastKey as varchar) + ',1); commit transaction; '
      execute(@sql)
   end
   else if @newParentType = 1
   begin
   	  set @sql='begin transaction; insert into ' + dbo.trim(@targetDB) + '..APORTMAP(APORT_KEY,CHILD_KEY,CHILD_TYPE) 
                    values(' + cast(@newParentKey as varchar) +','+ cast(@lastKey as varchar) + ',1); commit transaction; '
       execute(@sql)
   end
   
   
  -- update any notes
   execute absp_UserNotesClone 8,@aportKey,@lastKey,@targetDB
   
  -- now clone parts
   execute absp_TreeviewAPortfolioPartsClone @aportKey,@lastKey,@targetDB

   	-- create temp rtromap to allow updating keys
	create table #rtromap (rtro_key int, child_aply int, child_type int, new_key int)   
	set @sql =  
		'begin transaction; insert into #rtromap (rtro_key, child_aply, child_type) select * from ' + @targetDB + '..rtromap where RTRO_KEY in 
  			(select RTRO_KEY from ' + @targetDB + '..RTROINFO where PARENT_KEY = ' + str(@lastKey) + '); commit transaction; '
	execute sp_executesql @sql

  -- clone all children
   set @curs1 = cursor fast_forward for select CHILD_KEY,CHILD_TYPE from APORTMAP where  APORT_KEY = @aportKey
   open @curs1
   fetch next from @curs1 into @curs1_ChildKey,@curs1_ChildType
   while @@fetch_status = 0
   begin
      execute @newKey = absp_TreeviewGenericNodeClone @curs1_ChildKey,@curs1_ChildType,@lastKey,1,@aportKey,1,@createBy,@results,@temp_prog_table,1,@targetDB
	  
	  update #rtromap set new_key = @newKey where CHILD_APLY = @curs1_ChildKey and CHILD_TYPE = @curs1_ChildType
      
	 fetch next from @curs1 into @curs1_ChildKey,@curs1_ChildType
   end
   close @curs1 
   deallocate @curs1

	-- keep rtromap.child_aply = 0 when treaty applies to all children
	update #rtromap set NEW_KEY = 0 where NEW_KEY is NULL

	-- copy rows from #rtromap to rtromap to update keys to those resulting from the cloning pports and rports 
	set @sql = 'delete from ' + @targetDB + '..RTROMAP where RTRO_KEY in (select distinct RTRO_KEY from #rtromap)'
	execute sp_executesql @sql
	set @sql = 'begin transaction; insert into ' + @targetDB + '..RTROMAP (RTRO_KEY, CHILD_APLY, CHILD_TYPE) select RTRO_KEY, NEW_KEY, CHILD_TYPE from #rtromap; commit transaction; '
	execute sp_executesql @sql
   
      --If lookups are created, drop temp tables
      if @createdLookups = 1
      begin
      	exec absp_DropTmpLookupTables
      	if exists (Select 1 from tempdb.INFORMATION_SCHEMA.Tables Where Table_name='##TMP_LKUPCLONE_STATUS')
   	 	delete from ##TMP_LKUPCLONE_STATUS  where DBNAME=@targetDB AND SP_ID =@@SPID 
      end
   return @lastKey 
   
end