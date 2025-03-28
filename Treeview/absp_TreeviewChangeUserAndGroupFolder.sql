if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewChangeUserAndGroupFolder') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewChangeUserAndGroupFolder end

go

create  procedure absp_TreeviewChangeUserAndGroupFolder
        @nodeKey int,
        @newUser int = -1,
        @newGroup int = -1, -- - 1 means do not change this item
        @recursive bit = 0 -- - 1 means do not change this item
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure updates user_id and group_key of folder, irrespective to the users who have
created it. If executed with recursive option then it updates the user_id and group_key of 
nested folder, accumulation portfolio, re-insurance portfolio and primary portfolio. This in
turn updates the user_id and group_key of programs under the re-insurance portfolio. Again 
this in turn updates the user_id of the cases under the programs.

Returns:No Value

====================================================================================================

</pre>
</font>
##BD_END

##PD   @nodeKey 		^^ Key of folder node
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
   declare @curs3 cursor
   declare @curs4_CK4 int
   declare @curs4_CT4 smallint
   declare @curs4 cursor
   
   if @newUser = -1 and @newGroup = -1
   begin
      return
   end
   
   update FLDRINFO set CREATE_BY =
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
        end  where FOLDER_KEY = @nodeKey
        
   if @recursive = 1
   begin
      set @curs1 = cursor fast_forward for select CHILD_KEY as CK1 from FLDRMAP where FOLDER_KEY = @nodeKey and CHILD_TYPE = 0
      open @curs1
      fetch next from @curs1 into @curs1_CK1
      while @@fetch_status = 0
      begin
         execute absp_TreeviewGenericNodeChangeUserAndGroup @curs1_CK1,0,@newUser,@newGroup,@recursive
         fetch next from @curs1 into @curs1_CK1
      end
      close @curs1
      deallocate @curs1
      
      set @curs2 = cursor fast_forward for select CHILD_KEY as CK2 from FLDRMAP where FOLDER_KEY = @nodeKey and CHILD_TYPE = 1
      open @curs2
      fetch next from @curs2 into @curs2_CK2
      while @@fetch_status = 0
      begin
         execute absp_TreeviewGenericNodeChangeUserAndGroup @curs2_CK2,1,@newUser,@newGroup,@recursive
         fetch next from @curs2 into @curs2_CK2
      end
      close @curs2
      deallocate @curs2
      
      set @curs3 = cursor fast_forward for select CHILD_KEY as CK3 from FLDRMAP where FOLDER_KEY = @nodeKey and CHILD_TYPE = 2
      open @curs3
      fetch next from @curs3 into @curs3_CK3
      while @@fetch_status = 0
      begin
         execute absp_TreeviewGenericNodeChangeUserAndGroup @curs3_CK3,2,@newUser,@newGroup,@recursive
         fetch next from @curs3 into @curs3_CK3
      end
      close @curs3
      deallocate @curs3
      
      set @curs4 = cursor fast_forward for select CHILD_KEY as CK4,CHILD_TYPE as CT4 from FLDRMAP where FOLDER_KEY = @nodeKey and(CHILD_TYPE = 3 or CHILD_TYPE = 23)
      open @curs4
      fetch next from @curs4 into @curs4_CK4,@curs4_CT4
      while @@fetch_status = 0
      begin
         execute absp_TreeviewGenericNodeChangeUserAndGroup @curs4_CK4,@curs4_CT4,@newUser,@newGroup,@recursive
         fetch next from @curs4 into @curs4_CK4,@curs4_CT4
      end
      close @curs4
      deallocate @curs4
   end

end




