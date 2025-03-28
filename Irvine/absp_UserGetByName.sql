if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_UserGetByName') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_UserGetByName
end

go

create procedure  absp_UserGetByName  @UserName char(25) 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns a resultset for each user, containing all the user information and comma seperated
group keys of the groups the user belongs to.

Returns:       A single result set containing:

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

##PD  @userName ^^  The user group key which needs to be checked if in use or not. 

##RS  USER_KEY ^^  The key of the user.
##RS  USER_NAME ^^  The user name.
##RS  PASSWORD ^^  User Password used to log in.
##RS  STATUS ^^  The user status(Active/Inactive).
##RS  FIRSTNAME ^^  The first name of the user. 
##RS  LASTNAME ^^  The last name of the user. 
##RS  EMAIL_ADDR ^^  The email address of the user.
##RS  GROUP_KEY ^^  The GROUP_KEY of the base permissions group that the user belongs to.
##RS  GRPMEMLIST ^^  A comma seperated list of groups keys that the user belongs to.
*/

begin

set nocount on
   declare @grpKey int
   declare @grpKeyString varchar(max)
   declare @isValidUser int
   declare @swv_Curs_Uk int
   declare @curs cursor
   declare @swv_Curs2_Group_Key int
   declare @curs2 cursor
   set @grpKeyString = ''
   set @isValidUser = 0
   
  -- get the list of users
   set @curs = cursor fast_forward for select USER_KEY   from USERINFO where USER_NAME = @UserName
   open @curs
   fetch next from @curs into @swv_Curs_Uk
   while @@fetch_status = 0
   begin
      set @isValidUser = 1
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
      select   user_key as user_key, user_name as user_name, password as password, status as status, firstname as firstname, lastname as lastname, email_addr as email_addr, group_key as group_key, @grpKeyString as grpmemlst from userinfo where user_key = @swv_curs_uk
      fetch next from @curs into @swv_Curs_Uk
   end
   close @curs
   deallocate @curs
   
  -- return a empty resultset if the user is not a valid user otherwise on the java
  -- side it will get a undefined result set.
   if(@isValidUser = 0)
   begin
      select   user_key as user_key, user_name as user_name, password as password, status as status, firstname as firstname, lastname as lastname, email_addr as email_addr, group_key as group_key, @grpKeyString as grpmemlst from userinfo where user_name = @username
   end
end


