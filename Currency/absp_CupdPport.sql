if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CupdPport') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CupdPport
end
 go

create procedure absp_CupdPport @cupdKey int,@fldrKey int = 0,@aportKey int = 0,@pportKey int = 0,@policyKey int = 0,@siteKey int = 0,@doItFlag int = 0,@debugFlag int = 0 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:
This procedure inserts records in the CUPDCTRL table for the given pport are inserted in the 
CUPDCTRL table.

Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  @cupdKey ^^  The currency update key. 
##PD  @fldrKey ^^  The key of the folder node for which the currency conversion is to be done.
##PD  @aportKey ^^  The key of the aport node for which the currency conversion is to be done.
##PD  @pportKey ^^  The pport key if no policy and site key are given else the portId.
##PD  @policyKey ^^  The key of the policy for which the currency conversion is to be done.
##PD  @siteKey ^^  The key of the site for which the currency conversion is to be done.
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
   declare @portId int
   declare @msg varchar(255)
   declare @msgTxt varchar(255)
   declare @LPK int
   declare @CK int
   declare @PPK int
   declare @CK2 int
   set @me = 'absp_CupdPport: ' -- set to my name (name_of_proc plus 
   set @doIt = @doItFlag -- initialize
   set @debug = @debugFlag -- initialize
 --  set @cupdKey = @cupdKey
   if(@cupdKey > 0)
   begin
	insert into CUPDCTRL(CUPD_KEY,FOLDER_KEY,APORT_KEY,PPORT_KEY,LPORT_KEY,POLICY_KEY,SITE_KEY,STATUS) values(@cupdKey,@fldrKey,@aportKey,@pportKey,0,@policyKey,@siteKey,'N')
   end
   if @debug > 0
   begin
	  set @msgTxt = @me+'completed for @cupdKey = '+rtrim(ltrim(str(@cupdKey)))
	  execute absp_messageEx @msgTxt
   end
end