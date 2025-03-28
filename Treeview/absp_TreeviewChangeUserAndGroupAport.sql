if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewChangeUserAndGroupAport') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewChangeUserAndGroupAport
end

go

create   procedure  absp_TreeviewChangeUserAndGroupAport
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

This procedure updates user_id and group_key of an accumulation portfolio, irrespective to 
the users who have created the portfolio. If executed with recursive option then it updates  
the user_id and group_key of primary portfolio and re-insurance portfolio. This in turn 
updates the user_id and group_key of programs under the re-insurance portfolio. Again this in
turn updates the user_id of the cases under the programs.

Returns:No Value

====================================================================================================

</pre>
</font>
##BD_END

##PD   @nodeKey 	^^ Key of accumulation portfolio node
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
   declare @curs1_CK1 int
   declare @curs1 cursor
   declare @curs2_CK2 int
   declare @curs2 cursor
   declare @curs3_CK3 int
   declare @curs3_CT3 smallint
   declare @curs3 cursor
   
   if @newUser = -1 and @newGroup = -1
   begin
      return
   end
   update APRTINFO set CREATE_BY =
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
     end  where APORT_KEY = @nodeKey
   if @recursive = 1
   begin
      set @curs1 = cursor fast_forward for select CHILD_KEY  from APORTMAP where APORT_KEY = @nodeKey and CHILD_TYPE = 1
      open @curs1
      fetch next from @curs1 into @Curs1_CK1
      while @@fetch_status = 0
      begin
         execute absp_TreeviewGenericNodeChangeUserAndGroup @Curs1_CK1,1,@newUser,@newGroup,@recursive
         fetch next from @curs1 into @Curs1_CK1
      end
      close @curs1
      deallocate @curs1
      
      set @curs2 = cursor fast_forward for select CHILD_KEY  from APORTMAP where APORT_KEY = @nodeKey and CHILD_TYPE = 2
      open @curs2
      fetch next from @curs2 into @Curs2_CK2
      while @@fetch_status = 0
      begin
         execute absp_TreeviewGenericNodeChangeUserAndGroup @Curs2_CK2,2,@newUser,@newGroup,@recursive
         fetch next from @curs2 into @Curs2_CK2
      end
      close @curs2
      deallocate @curs2
      
      set @curs3 = cursor fast_forward for 
            select CHILD_KEY ,CHILD_TYPE as CT3 from APORTMAP where APORT_KEY = @nodeKey and(CHILD_TYPE = 3 or CHILD_TYPE = 23)
      open @curs3
      fetch next from @curs3 into @Curs3_CK3,@Curs3_CT3
      while @@fetch_status = 0
      begin
         execute absp_TreeviewGenericNodeChangeUserAndGroup @Curs3_CK3,@Curs3_CT3,@newUser,@newGroup,@recursive
         fetch next from @curs3 into @Curs3_CK3,@Curs3_CT3
      end
      close @curs3
      deallocate @curs3
   end

end




