
if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewAportfolioPartsClone') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewAportfolioPartsClone
end
 go
 
create procedure absp_TreeviewAportfolioPartsClone @oldAportKey int ,@newAportKey int, @targetDB varchar(130)=''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure clones all the aport parts in the database for a 
given aport node key.
Aport parts include the following:-
1) Retro Treaty Information
2) Retro Treaty Map
3) Retro Participation for each layer
4) Retro Treaty Layer Data
5) Retro Treaty Exclusions
6) Retro Treaty Industry Loss Triggers



Returns:       Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @oldAportKey ^^  The key of the aport for which the parts are to be cloned. 
##PD  @newAportKey ^^  The key of the destination aport for which the clones are created.

*/
as
begin
set nocount on
  -- this procedure will clone the parts of an APortfolio 
   declare @whereClause varchar(max)
   declare @progkeyTrio varchar(max)
   declare @whereClause2 varchar(max)
   declare @progkeyTrio2 varchar(max)
   declare @whereClause3 varchar(max)
   declare @progkeyTrio3 varchar(max)
   declare @newRtroKey int
   declare @newLayrKey int
   declare @tabSep char(10)
   declare @curs1_RKey int
   declare @curs1_TtypeID smallint  
   declare @curs2_RLayrKey int
   declare @sql varchar(max)
   
   if @targetDB=''
   	set @targetDB = DB_NAME()
   	
   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB

   execute  absp_GenericTableCloneSeparator @tabSep output
   -- now for each retro associated with that aport_key
  
   declare curs_rtro  cursor fast_forward  for 
          select  RTRO_KEY ,TTYPE_ID as TTYPE_ID from RTROINFO where PARENT_KEY = @oldAportKey and PARENT_TYP = 1
   open curs_rtro
   fetch next from curs_rtro into @curs1_RKey,@curs1_TtypeID 
   while @@fetch_status = 0
   begin
   
      set @whereClause = 'PARENT_KEY = '+STR(@oldAportKey)+' AND RTRO_KEY = '+STR(@curs1_RKey)
      set @progkeyTrio = 'INT'+@tabSep+'PARENT_KEY '+@tabSep+str(@newAportKey)
      
      -- copy over each retro individually getting the new rtrokey
     
      execute @newRtroKey = absp_GenericTableCloneRecords 'RTROINFO',1,@whereClause,@progkeyTrio,0,@targetDB,0
      print '@newRtroKey  '+ str(@newRtroKey)
         
      
      -- copy the rtromap table
      set @whereClause = 'RTRO_KEY = '+STR(@curs1_RKey)
      set @progkeyTrio = 'INT'+@tabSep+'RTRO_KEY '+@tabSep+STR(@newRtroKey)
      
      -- copy over each retro individually getting the new rtrokey
      execute absp_GenericTableCloneRecords 'RTROMAP',0,@whereClause,@progkeyTrio,0,@targetDB
      
      -- For Per Risk and Surplus Share the Reinsurer Information is at Treaty level and the
      -- Layer Key is always 0. So clone the records for each treaty
      
      if(@curs1_TtypeID = 6 or @curs1_TtypeID = 8)
      begin
      	    
      execute absp_GenericTableCloneRecords 'RTROPART',0,@whereClause,@progkeyTrio,0,@targetDB,0
     
         
      end
      -- SDG__00013342 -- add RTRO_KEY filter to avoid integrity violation
      -- now for each layer associated with that  RTRO_KEY
      
      declare curs2_trv  cursor fast_forward  for select  RTLAYR_KEY from RTROLAYR where RTRO_KEY = @curs1_RKey
      open curs2_trv
      fetch next from curs2_trv into @curs2_RLayrKey
      while @@fetch_status = 0
      begin
         set @whereClause = 'RTLAYR_KEY = '+STR(@curs2_RLayrKey)
         set @progkeyTrio = 'INT'+@tabSep+'RTRO_KEY '+@tabSep+STR(@newRtroKey)
         
         -- change over the CASE_KEY  
              
         execute @newLayrKey = absp_GenericTableCloneRecords 'RTROLAYR',1,@whereClause,@progkeyTrio,0,@targetDB,0     
         
         -- now for each layer we have to clone the pieces
         set @whereClause2 = 'RTRO_KEY = '+STR(@curs1_RKey)+' AND '+'RTLAYR_KEY = '+STR(@curs2_RLayrKey)
         set @progkeyTrio2 = 'INT'+@tabSep+' RTRO_KEY '+@tabSep+STR(@newRtroKey)+@tabSep+'INT'+@tabSep+' RTLAYR_KEY '+@tabSep+STR(@newLayrKey)
         
         -- change over the RTRO_KEY and layr_key
         --execute absp_GenericTableCloneRecords 'RTROTRIG',1,@whereClause2,@progkeyTrio2,0,@targetDB
         execute absp_GenericTableCloneRecords 'RTROEXCL',1,@whereClause2,@progkeyTrio2,0,@targetDB
         
         -- For Per Risk and Surplus Share the Reinsurer Information is at Treaty level and the
         -- Layer Key is always 0. So we do not need to clone the records for each layer.
         if(@curs1_TtypeID <> 6 and @curs1_TtypeID <> 8)
         begin
         
            execute absp_GenericTableCloneRecords 'RTROPART',0,@whereClause2,@progkeyTrio2,0,@targetDB ,0       
         end
         
      -- At this point, LineofBusiness on the target database has been populated with resolved lookup IDs and tags
      -- clone RtroLineOfBusiness Table with new RtLayerKey and new LineofBusinessID based on the matching LOB tag Name

      set @sql = 'begin transaction; insert into ' + @targetDB + '.dbo.RtroLineOfBusiness ' +
                  'select ' + rtrim(str(@newLayrKey)) + ' as RtLayerKey, l2.LineOfBusinessID ' + 
                  'from ( ' + @targetDB + '.dbo.LineOfBusiness l2 join LineOfBusiness l1 on l2.Name = l1.Name) ' +
                  'join RtroLineOfBusiness il1 on il1.LineOfBusinessID = l1.LineOfBusinessID ' +
                  'where il1.RtLayerKey = ' + rtrim(str(@curs2_RLayrKey))+'; commit transaction;'
      --print @sql
      execute(@sql)           
 
       
         fetch next from curs2_trv into @curs2_RLayrKey
      end
      close curs2_trv
      deallocate curs2_trv
      
      -- the zero = all_layers options
      set @whereClause3 = 'RTLAYR_KEY = 0 AND MT.RTRO_KEY = '+STR(@curs1_RKey)
      set @progkeyTrio3 = 'INT'+@tabSep+' RTRO_KEY '+@tabSep+STR(@newRtroKey)+@tabSep+'INT'+@tabSep+' RTLAYR_KEY '+@tabSep+STR(0)
      --execute absp_GenericTableCloneRecords 'RTROTRIG',1,@whereClause3,@progkeyTrio3,0,@targetDB
      execute absp_GenericTableCloneRecords 'RTROEXCL',1,@whereClause3,@progkeyTrio3,0,@targetDB
    
      -- For Per Risk and Surplus Share the Reinsurer Information is at Treaty level and the
      -- Layer Key is always 0. So we do not need to clone the records for each layer.
      if(@curs1_TtypeID <> 6 and @curs1_TtypeID <> 8)
      begin
      	
	 
         execute absp_GenericTableCloneRecords 'RTROPART',0,@whereClause3,@progkeyTrio3,0,@targetDB, 0
         
      end
      fetch next from curs_rtro into @curs1_RKey,@curs1_TtypeID 
   end
   close curs_rtro
   deallocate curs_rtro
end