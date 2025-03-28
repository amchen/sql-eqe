if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CupdAport') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CupdAport
end
go

create procedure absp_CupdAport @cupdKey int,@fldrKey int = 0,@aportKey int = 0,@doItFlag int = 0,@debugFlag int = 0 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:
This procedure inserts records in the CUPDCTRL table for each rport/pport under a given aport 
and calls the absp_CupdPport and absp_CupdRport procedures respectively for the database changes
required for currency conversion.

Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  @cupdKey ^^  The currency update key. 
##PD  @fldrKey ^^  The key of the parent folder for which the currency conversion is to be done.
##PD  @aportKey ^^  The key of the aport node for which the currency conversion is to be done.
##PD  @doItFlag ^^  The parameter is unused in the proc and the called procs.
##PD  @debugFlag ^^  The debug flag.

*/
as

begin

   set nocount on
   
  -- standard declares
   declare @me varchar(255)
   declare @debug int
   declare @doIt int
   declare @nodeKey int
   declare @nodeType int
   declare @msg varchar(255)
   declare @msgTxt varchar(255)
   declare @CK2 int
   declare @CK3 int
   
   set @me = 'absp_CupdAport: ' -- set to my name (name_of_proc plus 
   set @doIt = @doItFlag -- initialize
   set @debug = @debugFlag -- initialize
   if @debug > 0
   begin
	  set @msgTxt = @me+'starting: aportKey = '+rtrim(ltrim(str(@aportKey)))
	  execute absp_messageEx @msgTxt
   end
   set @cupdKey = @cupdKey
   if @cupdKey > 0
   begin
	-- SDG__00019498 - add an entry for the aport itself so its treaty layer data can be updated.
	-- This is the case when absp_CupdAport (@cupdKey, fldrKey = 0, @nodeKey, @doIt, @debug) is called by absp_CupdPrep with nodeType = 1 
	   if @fldrKey = 0 
	   begin
	   	insert into CUPDCTRL (CUPD_KEY, FOLDER_KEY, APORT_KEY,STATUS) values (@cupdKey,@fldrKey,@aportKey,'N')
	   end

	-- child pports
	  declare curs_ck2  cursor fast_forward for select distinct CHILD_KEY as CK2 from APORTMAP where APORT_KEY = @aportKey and CHILD_TYPE = 2
	  open curs_ck2
	  fetch next from curs_ck2 into @CK2
	  while @@fetch_status = 0
	  begin
		 insert into CUPDCTRL(CUPD_KEY,FOLDER_KEY,APORT_KEY,PPORT_KEY,STATUS) values(@cupdKey,@fldrKey,@aportKey,@CK2,'N')
		 execute absp_CupdPport @cupdKey,@fldrKey,@aportKey,@CK2,0,0,@doIt,@debug
		 fetch next from curs_ck2 into @CK2
	  end
	  close curs_ck2
	  deallocate curs_ck2
	
	-- child rports
	  declare curs_ck3  cursor fast_forward for select distinct CHILD_KEY as CK3 from APORTMAP where APORT_KEY = @aportKey and(CHILD_TYPE = 3 or CHILD_TYPE = 23)
	  open curs_ck3
	  fetch next from curs_ck3 into @CK3
	  while @@fetch_status = 0
	  begin
		 insert into CUPDCTRL(CUPD_KEY,FOLDER_KEY,APORT_KEY,RPORT_KEY,STATUS) values(@cupdKey,@fldrKey,@aportKey,@CK3,'N')
		 execute absp_CupdRport @cupdKey,@fldrKey,@aportKey,@CK3,@doIt,@debug
		 fetch next from curs_ck3 into @CK3
	  end
	  close curs_ck3
	  deallocate curs_ck3
   end
   if @debug > 0
   begin
      set @msgTxt = @me+'completed for @cupdKey = '+rtrim(ltrim(str(@cupdKey)))
      execute absp_messageEx @msgTxt
   end
end
