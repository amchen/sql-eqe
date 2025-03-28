if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewChangeUserAndGroupRport') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewChangeUserAndGroupRport
end

go

create  procedure absp_TreeviewChangeUserAndGroupRport
      @nodeKey int,@newUser int = -1,
      @newGroup int = -1, -- - 1 means do not change this item
      @recursive bit = 0
 
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure updates user_id and group_key of a re-insurance portfolio, irrespective to the
users who have created the portfolio. If executed with recursive option then it updates the 
user_id and group_key of the programs of this particular re-insurance portfolio. This in turn
updates the user_id of all the available cases for the concerned program.

Returns:No Value

====================================================================================================

</pre>
</font>
##BD_END

##PD   @nodeKey 	^^ Key of reinsurance portfolio node
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
   declare @rport_node_type int
   declare @prog_node_type int
   declare @curs1_CK1 int
   declare @curs1 cursor
   exec @rport_node_type = absp_Util_GetRPortType @nodeKey
   if @rport_node_type = 3
   begin
      set @prog_node_type = 7
   end
   else
   begin
      if @rport_node_type = 23
      begin
         set @prog_node_type = 27
      end
   end
   if @newUser = -1 and @newGroup = -1
   begin
      return
   end
   update RPRTINFO set CREATE_BY =
      case when @newUser > 0 then
   	@newUser
      else 
        CREATE_BY
      end,
      GROUP_KEY = 
      case when @newGroup > -1 then
           @newGroup
      else 
           GROUP_KEY
     end  where  RPORT_KEY = @nodeKey
   if @recursive = 1
   begin
      set @curs1 = cursor fast_forward for 
         select CHILD_KEY from RPORTMAP where RPORT_KEY = @nodeKey and(CHILD_TYPE = 7 or CHILD_TYPE = 27)
      open @curs1
      fetch next from @curs1 into @curs1_CK1
      while @@fetch_status = 0
      begin
         execute absp_TreeviewGenericNodeChangeUserAndGroup @curs1_CK1,@prog_node_type,@newUser,@newGroup,@recursive
         fetch next from @curs1 into @curs1_CK1
      end
      close @curs1
      deallocate @curs1
   end
  -- we commit whatever was requested

end


