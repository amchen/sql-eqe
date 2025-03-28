if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CupdProg') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CupdProg
end
 go

create procedure absp_CupdProg @cupdKey int,@fldrKey int = 0,@aportKey int = 0,@rportKey int,@progKey int,@doItFlag int = 0,@debugFlag int = 0 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:
This procedure finds the parent rport and the lport of a given program and calls the absp_CupdLport
procedure to perform the database changes required for a currency conversion.

Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  @cupdKey ^^  The currency update key. 
##PD  @fldrKey ^^  The key of the folder node for which the currency conversion is to be done.
##PD  @aportKey ^^  The key of the aport node for which the currency conversion is to be done.
##PD  @rportKey ^^  The key of the rport node.(Unused param)
##PD  @progKey ^^  The key of the program node for which the currency conversion is to be done.
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
	   declare @lportKey int
	   declare @msg varchar(255)
	   declare @msgTxt01 varchar(255)
	   set @me = 'absp_CupdProg: ' -- set to my name (name_of_proc plus 
	   set @doIt = @doItFlag -- initialize
	   set @debug = @debugFlag -- initialize
	   if @debug > 0
	   begin
		  set @msgTxt01 = @me+'starting: progKey = '+rtrim(ltrim(str(@progKey)))
		  execute absp_messageEx @msgTxt01
	   end
	   set @cupdKey = @cupdKey
	   if(@cupdKey > 0)
	   begin
		insert into CUPDCTRL(CUPD_KEY,FOLDER_KEY,APORT_KEY,RPORT_KEY,PROG_KEY,STATUS) values(@cupdKey,@fldrKey,@aportKey,@rportKey,@progKey,'N')
	   end
	   if @debug > 0
	   begin
		  set @msgTxt01 = @me+'completed for @cupdKey = '+rtrim(ltrim(str(@cupdKey)))
		  execute absp_messageEx @msgTxt01
	   end
end




