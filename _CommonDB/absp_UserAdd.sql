if exists(select * from sysobjects where id = object_id(N'absp_UserAdd') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_UserAdd
end
 go
create procedure absp_UserAdd @usrName char(25),@usrPwd char(42),@usrFirstName char(25),@usrLastName char(25),@usrEmail char(120),@usrGroupKey int 
/* 
##BD_BEGIN  
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose: 

This function creates a new user by inserting a record in USERINFO with the 
given values and returns the new userKey.


Returns:      The key of the new user 
=================================================================================
</pre> 
</font> 
##BD_END 

##PD  @usrName ^^ User Name.
##PD  @usrPwd ^^ User Password.
##PD  @usrFirstName ^^ The key of the child node.
##PD  @usrLastName ^^ The type of the child node.
##PD  @usrEmail ^^ Email of user.
##PD  @usrGroupKey ^^ Key of the group the user belongs to.

##RD @retVal ^^ The new user key.

*/
as
begin

   set nocount on
   
   declare @retVal int
   insert into USERINFO(USER_NAME,PASSWORD,STATUS,FIRSTNAME,LASTNAME,EMAIL_ADDR,GROUP_KEY) values(@usrName,@usrPwd,'Y',@usrFirstName,@usrLastName,@usrEmail,@usrGroupKey)
   set @retVal = @@IDENTITY
   return @retVal
end



