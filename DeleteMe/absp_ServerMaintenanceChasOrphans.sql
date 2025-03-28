if exists(select 1 FROM SYSOBJECTS WHERE id = object_id(N'absp_ServerMaintenanceChasOrphans') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_ServerMaintenanceChasOrphans
end
go

create procedure absp_ServerMaintenanceChasOrphans as
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure deletes all the records from CHASDATA having the CHAS_KEY which has no
entry in CHASINFO table.

Returns:	Nothing

====================================================================================================

</pre>
</font>
##BD_END

*/
begin
  set nocount on
  
  /*
  This procedure gets the max CHAS_KEY from CHASDATA and CHASINFO and then decrements the key
  and if the key is not in CHASINFO it tries to delete it from CHASDATA.
  
  */
   -- standard declares
   declare @me varchar(255)
   declare @debug int
   declare @msg varchar(255)
   declare @maxChasKey int
   declare @msgText varchar(255)
   
  -- initialize standard items
   set @me = 'absp_ServerMaintenanceChasOrphans: ' -- set to my name Procedure Name
   set @debug = 1 -- initialize
   set @msg = @me+'starting'
   
   if @debug > 0
   begin
      execute absp_messageEx @msg
   end
   
   execute absp_messageEx 'select max(CHAS_KEY) into @maxChasKey from CHASDATA'
   select  @maxChasKey = max(chas_key)  from CHASDATA
   set @maxChasKey = isnull(@maxChasKey,0)
   
   loop1: while 1 = 1
   begin
      if not exists(select  1 from CHASINFO where CHAS_KEY = @maxChasKey)
      begin
         set @msgText = 'delete from CHASDATA where chas_key = '+str(@maxChasKey)
         execute absp_MessageEx @msgText
         
         delete from CHASDATA where chas_key = @maxChasKey

      end
      set @maxChasKey = @maxChasKey -1
      if(@maxChasKey < 1)
      begin
         break
      end
   end
  -------------- end --------------------
   if @debug > 0
   begin
      set @msg = @me+'complete'
      execute absp_messageEx @msg
   end
end




