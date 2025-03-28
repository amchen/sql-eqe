if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CupdFolder') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CupdFolder
end
 go

create procedure absp_CupdFolder @cupdKey int,@fldrKey int,@doItFlag int = 0,@debugFlag int = 0 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure inserts records in the CUPDCTRL table for each folder/aport/pport/rport under a 
given folder and calls the absp_CupdFolder,absp_CupdAport,absp_CupdPPort,absp_CupdRport procedures
respectively for the database changes required for currency conversions.

Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  @cupdKey ^^  The currency update key. 
##PD  @fldrKey ^^  The key of the folder node for which the currency conversion is to be done.
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
   declare @CK0 int
   declare curs0  cursor fast_forward local for select distinct CHILD_KEY as CK0 from FLDRMAP where FOLDER_KEY = @fldrKey and CHILD_TYPE = 0
   declare @CK1 int
   declare curs1  cursor fast_forward local for select distinct CHILD_KEY as CK1 from FLDRMAP where FOLDER_KEY = @fldrKey and CHILD_TYPE = 1
   declare @CK2 int
   declare curs2  cursor fast_forward local for select distinct CHILD_KEY as CK2 from FLDRMAP where FOLDER_KEY = @fldrKey and CHILD_TYPE = 2
   declare @CK3 int
   declare curs3  cursor fast_forward local for select distinct CHILD_KEY as CK3 from FLDRMAP where FOLDER_KEY = @fldrKey and(CHILD_TYPE = 3 or CHILD_TYPE = 23)
   set @me = 'absp_CupdFolder: ' -- set to my name (name_of_proc plus 
   set @doIt = @doItFlag -- initialize
   set @debug = @debugFlag -- initialize
   if @debug > 0
   begin
      set @msgTxt = @me+'starting: fldrKey = '+rtrim(ltrim(str(@fldrKey)))
      execute absp_messageEx @msgTxt
   end
   set @cupdKey = @cupdKey
   if @cupdKey > 0
   begin
	-- child folders
	  open curs0
	  fetch next from curs0 into @CK0
	  while @@fetch_status = 0
	  begin
		 insert into CUPDCTRL(CUPD_KEY,FOLDER_KEY,STATUS) values(@cupdKey,@CK0,'N')
		 execute absp_CupdFolder @cupdKey,@CK0,@doItFlag,@debugFlag
		 fetch next from curs0 into @CK0
	  end
	  close curs0
	  deallocate curs0
	-- child aports
	  open curs1
	  fetch next from curs1 into @CK1
	  while @@fetch_status = 0
	  begin
		 insert into CUPDCTRL(CUPD_KEY,FOLDER_KEY,APORT_KEY,STATUS) values(@cupdKey,@fldrKey,@CK1,'N')
		 execute absp_CupdAport @cupdKey,@fldrKey,@CK1,@doIt,@debug
		 fetch next from curs1 into @CK1
	  end
	  close curs1
	  deallocate curs1
	-- child pports
	  open curs2
	  fetch next from curs2 into @CK2
	  while @@fetch_status = 0
	  begin
		 insert into CUPDCTRL(CUPD_KEY,FOLDER_KEY,PPORT_KEY,STATUS) values(@cupdKey,@fldrKey,@CK2,'N')
		 execute absp_CupdPport @cupdKey,@fldrKey,0,@CK2,0,0,@doIt,@debug
		 fetch next from curs2 into @CK2
	  end
	  close curs2
	  deallocate curs2
	-- child rports
	  open curs3
	  fetch next from curs3 into @CK3
	  while @@fetch_status = 0
	  begin
		 insert into CUPDCTRL(CUPD_KEY,FOLDER_KEY,RPORT_KEY,STATUS) values(@cupdKey,@fldrKey,@CK3,'N')
		 execute absp_CupdRport @cupdKey,@fldrKey,0,@CK3,@doIt,@debug
		 fetch next from curs3 into @CK3
	  end
	  close curs3
	  deallocate curs3
   end
   if @debug > 0
   begin
	  set @msgTxt = @me+'completed for @cupdKey = '+rtrim(ltrim(str(@cupdKey)))
	  execute absp_messageEx @msgTxt
   end
end




