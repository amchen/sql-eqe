if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewChangeUserAndGroupProg') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewChangeUserAndGroupProg
end

go

create  procedure absp_TreeviewChangeUserAndGroupProg 
  @nodeKey int,
  @newUser int = -1,
  @newGroup int = -1, -- - 1 means do not change this item
  @recursive bit = 0
  
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure updates user_id and group_key for a particular program, irrespective to whoever
had actually created them. It also updates the user_id of all the cases under a particular 
program as per parameter supplied, through another stored procedure.

Returns:No Value

====================================================================================================

</pre>
</font>
##BD_END

##PD   @nodeKey 	^^ Key of the program node
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
  --MTRPORT = 23;
  --MTPROG = 27;
  --MTCASE = 30;
   declare @prog_node_type int
   declare @case_node_type int
   declare @curs1_CK1 int
   declare @curs1 cursor
   exec @prog_node_type = absp_Util_GetProgramType @nodeKey
   if @prog_node_type = 7
   begin
      set @case_node_type = 10
   end
   else
   begin
      if @prog_node_type = 27
      begin
         set @case_node_type = 30
      end
   end
   if @newUser = -1 and @newGroup = -1
   begin
      return
   end
   update PROGINFO 
     set CREATE_BY = 
     case when @newUser > 0 then
   	@newUser
     else 
        CREATE_BY
     end,
     GROUP_KEY  = 
     case when @newGroup > -1 then
        @newGroup
     else 
        GROUP_KEY
     end  where  PROG_KEY = @nodeKey
     
   if @recursive = 1
   begin
      set @curs1 = cursor fast_forward for select CASE_KEY from CASEINFO where PROG_KEY = @nodeKey
      open @curs1
      fetch next from @curs1 into @curs1_CK1
      while @@fetch_status = 0
      begin
         execute absp_TreeviewGenericNodeChangeUserAndGroup @curs1_CK1,@case_node_type,@newUser,@newGroup,@recursive
         fetch next from @curs1 into @curs1_CK1
      end
      close @curs1
      deallocate @curs1
   end
end





