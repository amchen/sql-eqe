
if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewChasClone') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewChasClone
end
 go

create procedure absp_TreeviewChasClone @chasKey int, @targetDB varchar(130)=''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure clones the records of the CHAS tables for a given chas key.

Returns:       A single value @lastKey
@lastKey >0 If the given chasKey is valid (the newly cloned chasKey)
@lastKey =0 If the given chasKey is invalid
====================================================================================================
</pre>
</font>
##BD_END

##PD  @ChasKey ^^  The chas key for which the chas records are to be cloned. 

##RD  @lastKey ^^  The new chas key. 

*/
as
begin
 
   set nocount on
   
 -- this procedure will clone the CHAS tables
   declare @lastKey int
   declare @whereClause varchar(255)
   declare @progkeyTrio varchar(255)
   declare @tabSep char(2)
   declare @tempTableExits int
   declare @sql varchar(max)
   declare @currSkKey int
   
   set @tempTableExits = 0

   if @targetDB=''
   		set @targetDB = DB_NAME()
   		
   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB

   execute absp_GenericTableCloneSeparator @tabSep output
   
  -- copy into a new one with the new unique name
   set @whereClause = 'CHAS_KEY = '+cast(@chasKey as char)
   set @progkeyTrio = 'int'+@tabSep+'CHAS_KEY '+@tabSep+cast(@chasKey as char)
   
   execute @lastKey = absp_GenericTableCloneRecords 'CHASINFO',1,@whereClause,@progkeyTrio,0, @targetDB
   
   --Update CURRSK_KEY of targetDB
   select @currSkKey = CURRSK_KEY from CFLDRINFO where DB_NAME = substring(@targetDB,2,len(@targetdb)-2)
   set @sql = 'begin transaction; update ' + dbo.trim(@targetDB) + '..CHASINFO 
                     set CHASINFO.CURRSK_KEY = ' + str(@currSkKey) +
                     ' where CHAS_KEY = '+str(@lastKey)+'; commit transaction; '
         
   execute(@sql)
   
  -- Fixed Defect: SDG__00013454
  -- A Copy/Paste of a PROGRAM with WCC imported data does not update CHASINFO.FILE_KEY properly
  -- Here we will check if we need to update the FILE_KEY. We only need to perform
  -- the update if this is called from Program clone.
  -- Check if temp table exists if not nothing to do
  
   execute @tempTableExits = absp_Util_CheckIfTableExists '#FILE_KEY_MAP_TBL'
   if(@tempTableExits = 1)
   begin
      print 'update CHASINFO, #FILE_KEY_MAP_TBL t1 set CHASINFO.FILE_KEY = t1.NEW_FILEKEY where CHASINFO.FILE_KEY = t1.OLD_FILEKEY and CHAS_KEY = '+str(@lastKey)
      
      set @sql = 'begin transaction; update ' + dbo.trim(@targetDB) + '..CHASINFO 
                  set CHASINFO.FILE_KEY = t1.NEW_FILEKEY 
                  from  #FILE_KEY_MAP_TBL as t1
                  where
                  CHASINFO.FILE_KEY = t1.OLD_FILEKEY 
                  and CHAS_KEY = '+str(@lastKey)+'; commit transaction; '
      
      execute(@sql)
   end
  -- update the parts that depend on chas key
   execute absp_TreeviewChasPartsClone @chasKey,@lastKey,@targetDB
  -- data and errs
   set @progkeyTrio = 'int'+@tabSep+'CHAS_KEY '+@tabSep+cast(@lastKey as char)
   execute absp_GenericTableCloneRecords 'CHASDATA',0,@whereClause,@progkeyTrio,0,@targetDB,0
   execute absp_GenericTableCloneRecords 'CHASERRS',0,@whereClause,@progkeyTrio,0,@targetDB
   return @lastKey
end