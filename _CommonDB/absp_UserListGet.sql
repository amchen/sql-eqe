if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_UserListGet') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_UserListGet
end

go

create procedure absp_UserListGet as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:   MSSQL
Purpose:

This procedure returns multiple resultsets; each resultset contains all the user information for each
existent user in the table USERINFO and a comma separated list of group keys of the groups that the user
belongs to.

Returns:       Multiple result sets, each containing:

1. User Key
2. User Name
3. Password
4. Status
5. FirstName
6. Last Name
7. Email Address
8. Group Key
9. A comma seperated list of groups keys that it belongs to.
====================================================================================================
</pre>
</font>
##BD_END

##RS  USER_KEY ^^  The key of the user.
##RS  USER_NAME ^^  The user name.
##RS  PASSWORD ^^  User Password used to log in.
##RS  STATUS ^^  The user status(Active/Inactive).
##RS  FIRSTNAME ^^  The first name of the user. 
##RS  LASTNAME ^^  The last name of the user. 
##RS  EMAIL_ADDR ^^  The email address of the user.
##RS  GROUP_KEY ^^  The GROUP_KEY of the base permissions group that the user belongs to.
##RS  GRPMEMLST ^^  A comma seperated list of groups keys that the user belongs to.
*/
begin

   set nocount on
   declare @grpKey int
   declare @grpKeyString varchar(max)
   declare @swv_Curs_Uk int
   declare @curs cursor
   declare @swv_Curs2_Group_Key int
   declare @curs2 cursor
  -- get the list of users
  
   set @curs = cursor fast_forward for select USER_KEY  from USERINFO
   open @curs
   fetch next from @curs into @swv_Curs_Uk
   while @@fetch_status = 0
   begin
      set @grpKeyString = ''
      set @grpKey = 88
    -- for each user get all his groups
    
      -- create a comma separated string of them
      set @curs2 = cursor fast_forward for select GROUP_KEY from USRGPMEM where USER_KEY = @swv_Curs_Uk
      open @curs2
      fetch next from @curs2 into @swv_Curs2_Group_Key
      while @@fetch_status = 0
      begin
         set @grpKeyString = @grpKeyString+rtrim(ltrim(str(@swv_Curs2_Group_Key)))+','
         fetch next from @curs2 into @swv_Curs2_Group_Key
      end
      close @curs2
      deallocate @curs2
    -- now get the userinfo for him
      select   USER_KEY as USER_KEY, USER_NAME AS USER_NAME, PASSWORD as PASSWORD, STATUS as STATUS, FIRSTNAME as FIRSTNAME, LASTNAME as LASTNAME, EMAIL_ADDR as EMAIL_ADDR, GROUP_KEY as GROUP_KEY, @GRPKEYSTRING as GRPMEMLST FROM USERINFO WHERE USER_KEY = @swv_Curs_Uk
      fetch next from @curs into @swv_Curs_Uk
   end
   close @curs
   deallocate @curs
end


