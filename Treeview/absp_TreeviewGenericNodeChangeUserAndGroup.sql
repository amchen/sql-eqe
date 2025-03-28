if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewGenericNodeChangeUserAndGroup') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewGenericNodeChangeUserAndGroup
end

go

create procedure absp_TreeviewGenericNodeChangeUserAndGroup @nodeKey int,@nodeType int,@newUser int = -1,@newGroup int = -- - 1 means do not change this item
-1,@recursive bit = -- - 1 means do not change this item
0 
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure updates user_id and group_key of different types of nodes irrespective to the
users who have created it. If executed with recursive option then it updates the user_id and
group_key of nested level of nodes. The type of nodes includes folder, primary portfolio, 
accumulation portfolio, re-insurance portfolio,	program and case.

Returns:No Value

====================================================================================================

</pre>
</font>
##BD_END

##PD   @nodeKey 	^^ Key of node
##PD   @nodeType 	^^ Type of node
##PD   @newUser		^^ User id (- 1 means do not change this item)
##PD   @newGroup 	^^ User group key (- 1 means do not change this item)
##PD   @recursive	^^ 1 For recursive and 0 for non recursive

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
  --MTRPORT = 23;
  --MTPROG = 27;
  --MTCASE = 30;
  --Currency node (folder realy) = 12
   if @newUser = -1 and @newGroup = -1
   begin
      return
   end
  -- call the correct function based on the node type
   if @nodeType = 0
   begin
      execute absp_TreeviewChangeUserAndGroupFolder @nodeKey,@newUser,@newGroup,@recursive
   end
   else
   begin
      if @nodeType = 1
      begin
         execute absp_TreeviewChangeUserAndGroupAport @nodeKey,@newUser,@newGroup,@recursive
      end
      else
      begin
         if @nodeType = 2
         begin
            execute absp_TreeviewChangeUserAndGroupPport @nodeKey,@newUser,@newGroup,@recursive
         end
         else
         begin
            if @nodeType = 3
            begin
               execute absp_TreeviewChangeUserAndGroupRport @nodeKey,@newUser,@newGroup,@recursive
            end
            else
            begin
               if @nodeType = 23
               begin
                  execute absp_TreeviewChangeUserAndGroupRport @nodeKey,@newUser,@newGroup,@recursive
               end
               else
               begin
                  if @nodeType = 7
                  begin
                     execute absp_TreeviewChangeUserAndGroupProg @nodeKey,@newUser,@newGroup,@recursive
                  end
                  else
                  begin
                     if @nodeType = 27
                     begin
                        execute absp_TreeviewChangeUserAndGroupProg @nodeKey,@newUser,@newGroup,@recursive
                     end
                     else
                     begin
                        if @nodeType = 10
                        begin
                           execute absp_TreeviewChangeUserAndGroupCase @nodeKey,@newUser,@newGroup,@recursive
                        end
                        else
                        begin
                           if @nodeType = 30
                           begin
                              execute absp_TreeviewChangeUserAndGroupCase @nodeKey,@newUser,@newGroup,@recursive
                           end
                           else
                           begin
                              if @nodeType = 12
                              begin
                                 execute absp_TreeviewChangeUserAndGroupFolder @nodeKey,@newUser,@newGroup,@recursive
                              end
                           end
                        end
                     end
                  end
               end
            end
         end
      end
   end
  -- we commit whatever was requested
 --  commit work
end





