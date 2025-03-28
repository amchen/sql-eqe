if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewChangeUserAndGroupCase') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewChangeUserAndGroupCase
end

go

create  procedure absp_TreeviewChangeUserAndGroupCase @nodeKey int,@newUser int = -1,@newGroup int = -- - 1 means do not change this item
-1,@recursive bit = -- - 1 means do not change this item
0 
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure updates "created by user id" for all the available cases.

Returns:No Value

====================================================================================================

</pre>
</font>
##BD_END

##PD   @nodeKey 		^^ Key of the case node
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
   update CASEINFO set CREATE_BY
   = case when @newUser > 0 then
   @newUser
   else CREATE_BY
end
  -- we commit whatever was requested
  -- commit work
end



