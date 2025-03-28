if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewChasPartsClone') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewChasPartsClone
end
go

create procedure absp_TreeviewChasPartsClone @oldChasKey int, @newChasKey int, @targetDB varchar(130)=''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure clones all the parts of a Chas Key.

Returns:       Nothing
====================================================================================================
</pre>
</font>
##BD_END

##PD  @oldChasKey ^^  The chas key whose parts are to be cloned. 
##PD  @newChasKey ^^  The new chas key for the clone records.

*/
as
begin
  -- clones all the child parts of a Chas key
   
   set nocount on
   
   declare @whereClause varchar(4000)
   declare @progkeyTrio varchar(4000)
   declare @whereClause2 varchar(4000)
   declare @progkeyTrio2 varchar(4000)
   declare @newPtfKey int
   declare @tabSep char(10)
   declare @cursChas_ChasPTFKey int
    
   if @targetDB=''
   		set @targetDB = DB_NAME()
   		
   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB

   execute absp_GenericTableCloneSeparator @tabSep output 
   
  -- now for each ptf associated with that chas_key
   declare cursChas cursor fast_forward for select  CHASPTFKEY from CHASPTF where CHAS_KEY = @oldChasKey
   open cursChas
   fetch next from cursChas into @cursChas_ChasPTFKey
   while @@fetch_status = 0
   begin
      set @whereClause = 'CHASPTFKEY = '+cast(@cursChas_ChasPTFKey as char)+' and '+'CHAS_KEY = '+cast(@oldChasKey as char)
      set @progkeyTrio = 'INT'+@tabSep+'CHAS_KEY '+@tabSep+cast(@newChasKey as char)
    
      -- change over the CHAS_KEY
      execute @newPtfKey = absp_GenericTableCloneRecords 'CHASPTF',1,@whereClause,@progkeyTrio,0,@targetDB

      -- now for each ptf we have to clone the parms
      set @whereClause2 = 'CHAS_KEY = '+cast(@oldChasKey as char)+' and '+'CHASPTFKEY = '+cast(@cursChas_ChasPTFKey as char)
      set @progkeyTrio2 = 'INT'+@tabSep+' CHAS_KEY '+@tabSep+cast(@newChasKey as char)+@tabSep+'INT'+@tabSep+' CHASPTFKEY '+@tabSep+cast(@newPtfKey as char)
    
      -- change over the parms
      execute absp_GenericTableCloneRecords 'CHASPARM',0,@whereClause2,@progkeyTrio2, 0,@targetDB,0
      fetch next from cursChas into @cursChas_ChasPTFKey
   end
   close cursChas
   deallocate cursChas
end




