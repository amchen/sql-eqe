
if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewCasePartsClone') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewCasePartsClone
end
 go
create procedure absp_TreeviewCasePartsClone @oldCaseKey int ,@newCaseKey int, @targetDB varchar(130)=''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure clones all the related treaty case information for a given case.
Related Treaty Case information includes the following:-
1) The treaty Case Exclusions
2) The treaty Case Reinstatements
3) The treaty Case Industry Loss Triggers
4) The treaty Case Layer Data

Returns:       Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @oldCaseKey ^^  The key of the case whose parts are to be cloned. 
##PD  @newCaseKey ^^  The new case key to which the new case parts are to be attached.
*/
as
begin
  -- clones all the child parts of a Case
  
   set nocount on
   
   declare @whereClause varchar(max)
   declare @progkeyTrio varchar(max)
   declare @whereClause2 varchar(max)
   declare @progkeyTrio2 varchar(max)
   declare @whereClause3 varchar(max)
   declare @progkeyTrio3 varchar(max)
   declare @newLayrKey int
   declare @tabSep char(10)
   declare @oldCalseLayrKey int
   declare @sql varchar(max)
   
   if @targetDB=''
   		set @targetDB = DB_NAME()
   		
   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB

   execute absp_GenericTableCloneSeparator  @tabSep output
   
   -- now for each layr associated with that case_key
   
   declare curs2_Cslayr  cursor fast_forward  for select  CSLAYR_KEY from  CASELAYR where CASE_KEY = @oldCaseKey and CSLAYR_KEY > 0
   open curs2_Cslayr
   fetch next from curs2_Cslayr into @oldCalseLayrKey
   while @@fetch_status = 0
   begin
      set @whereClause = 'CSLAYR_KEY = '+cast(@oldCalseLayrKey as char)
      set @progkeyTrio = 'int'+@tabSep+'CASE_KEY '+@tabSep+cast(@newCaseKey as char)
       -- change over the CASE_KEY
       
      execute @newLayrKey = absp_GenericTableCloneRecords 'CASELAYR',1,@whereClause,@progkeyTrio,0,@targetDB  	
      
      -- now for each layer we have to clone the pieces
      set @whereClause2 = 'CSLAYR_KEY = '+cast(@oldCalseLayrKey as char)
      set @progkeyTrio2 = 'int'+@tabSep+' CASE_KEY '+@tabSep+cast(@newCaseKey as char)+@tabSep+'int'+@tabSep+' CSLAYR_KEY '+@tabSep+cast(@newLayrKey as char)
      
      -- change over the CASE_KEY an layr_key
      --execute absp_GenericTableCloneRecords 'CASETRIG',1,@whereClause2,@progkeyTrio2,0,@targetDB
      execute absp_GenericTableCloneRecords 'CASEEXCL',1,@whereClause2,@progkeyTrio2,0,@targetDB
      execute absp_GenericTableCloneRecords 'CASEREIN',1,@whereClause2,@progkeyTrio2,0,@targetDB
      
      if substring(@targetDB,2,len(@targetdb)-2)<>DB_NAME()
      begin
      	--Clone CROL record if new and update reference
      	execute absp_CrolInfoClone  @oldCalseLayrKey, @newCaseKey, @targetDB
      end
      
      	-- At this point, LineofBusiness on the target database has been populated with resolved lookup IDs and tags
      	-- clone CaseLineOfBusiness Table with new CsLayerKey and new LineofBusinessID based on the matching LOB tag Name
      	set @sql = 'begin transaction; insert into ' + @targetDB + '.dbo.CaseLineOfBusiness ' +
                  'select distinct ' + rtrim(str(@newLayrKey)) + ' as CsLayerKey, l2.LineOfBusinessID ' + 
                  'from ( ' + @targetDB + '.dbo.LineOfBusiness l2 join LineOfBusiness l1 on l2.Name = l1.Name) ' +
                  'join CaseLineOfBusiness cl1 on cl1.LineOfBusinessID = l1.LineOfBusinessID ' +
                  'where cl1.CsLayerKey = ' + rtrim(str(@oldCalseLayrKey))+'; commit transaction; '
      	--print @sql
      	execute(@sql)
      	  
               
      fetch next from curs2_Cslayr into @oldCalseLayrKey
   end
   close curs2_Cslayr
   deallocate curs2_Cslayr
   
  -- the zero =all_layers options
   set @whereClause3 = 'CSLAYR_KEY = 0 and MT.CASE_KEY = '+cast(@oldCaseKey as char)
   set @progkeyTrio3 = 'int'+@tabSep+' CASE_KEY '+@tabSep+cast(@newCaseKey as char)+@tabSep+'int'+@tabSep+' CSLAYR_KEY '+@tabSep+cast(0 as char)
   --execute absp_GenericTableCloneRecords 'CASETRIG',1,@whereClause3,@progkeyTrio3,0,@targetDB
   execute absp_GenericTableCloneRecords 'CASEEXCL',1,@whereClause3,@progkeyTrio3,0,@targetDB
   execute absp_GenericTableCloneRecords 'CASEREIN',1,@whereClause3,@progkeyTrio3,0,@targetDB
end