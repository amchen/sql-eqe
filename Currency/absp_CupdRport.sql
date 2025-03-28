if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CupdRport') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CupdRport
end
 go

create procedure absp_CupdRport @cupdKey int,@fldrKey int = 0,@aportKey int = 0,@rportKey int,@doItFlag int = 0,@debugFlag int = 0 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:
This procedure inserts records in the CUPDCTRL table for each program under a given rport 
and calls the absp_CupdProg procedure for the database changes for required currency conversion.

Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  @cupdKey ^^  The currency update key. 
##PD  @fldrKey ^^  The key of the parent folder node for which the currency conversion is to be done.
##PD  @aportKey ^^  The key of the parent aport node for which the currency conversion is to be done.
##PD  @rportKey ^^  The key of the rport node for which the currency conversion is to be done.
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
	declare @msgTxt01 varchar(255)
	declare @CK1 int
   
	set @me = 'absp_CupdRport: ' -- set to my name (name_of_proc plus 
	set @doIt = @doItFlag -- initialize
	set @debug = @debugFlag -- initialize
	if @debug > 0
	begin
		set @msgTxt01 = @me+'starting: rportKey = '+rtrim(ltrim(str(@rportKey)))
		execute absp_messageEx @msgTxt01
	end
	set @cupdKey = @cupdKey
	if @cupdKey > 0
	begin
	    declare curs_child_key  cursor fast_forward for select distinct CHILD_KEY from RPORTMAP where RPORT_KEY = @rportKey and(CHILD_TYPE = 7 or CHILD_TYPE = 27)
		open curs_child_key
		fetch next from curs_child_key into @CK1
		while @@fetch_status = 0
		begin
			insert into CUPDCTRL(CUPD_KEY,FOLDER_KEY,APORT_KEY,RPORT_KEY,PROG_KEY,STATUS) values(@cupdKey,@fldrKey,@aportKey,@rportKey,@CK1,'N')
			execute absp_CupdProg @cupdKey,@fldrKey,@aportKey,@rportKey,@CK1,@doIt,@debug
			fetch next from curs_child_key into @CK1
		end
		close curs_child_key
		deallocate curs_child_key
	end
	if @debug > 0
	begin
		set @msgTxt01 = @me+'completed for @cupdKey = '+rtrim(ltrim(str(@cupdKey)))
		execute absp_messageEx @msgTxt01
	end
end