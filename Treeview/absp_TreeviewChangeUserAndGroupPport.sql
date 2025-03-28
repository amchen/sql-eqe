if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewChangeUserAndGroupPport') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewChangeUserAndGroupPport
end

go

create  procedure absp_TreeviewChangeUserAndGroupPport @nodeKey int,@newUser int = -1,@newGroup int = -- - 1 means do not change this item
-1,@recursive bit = -- - 1 means do not change this item
0 
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure updates user_key and group_key of primary portfolio irrespective to users who 
have created the portfolio.

Returns:No Value

====================================================================================================

</pre>
</font>
##BD_END

##PD   @nodeKey 		^^ Key of the pport node
##PD   @newUser		^^ User id (- 1 means do not change this item)
##PD   @newGroup 	^^ User group key (- 1 means do not change this item)
##PD   @recursive	^^ 1 For recurrsive and 0 for non recurrsive

*/
as
begin
 
   set nocount on
   
 --Folder = 0;
  --APort = 1;
  --PPort = 2;
  --RPort = 3;
  --FPort = 4;
  --Acct = 5;
  --Cert = 6;
  --Prog = 7;
  --Lport = 8;
  --Case = 10;
   if @newUser = -1 and @newGroup = -1
   begin
      return
   end
   update PPRTINFO set CREATE_BY
   = case when @newUser > 0 then
   @newUser
   else CREATE_BY
end,GROUP_KEY
   = case when @newGroup > -1 then
   @newGroup
   else GROUP_KEY
end  where
   PPORT_KEY = @nodeKey
  -- we commit whatever was requested
   --commit work
end



