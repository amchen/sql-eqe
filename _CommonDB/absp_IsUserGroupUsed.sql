if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_IsUserGroupUsed') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_IsUserGroupUsed
end
 go

create procedure absp_IsUserGroupUsed @userGroupKey int 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure checks if a user group is in use by users or portfolios.

Returns:       A value @retVal
1. @retVal = 1, when the given user group is in use.
2. @retVal = 0, when the given user group is not in use.               
====================================================================================================
</pre>
</font>
##BD_END

##PD  @userGroupKey ^^  The user group key which needs to be checked if in use or not. 

##RD  @retVal ^^  A return value, signifying whether the an user group is in use or not.

*/
as
begin

set nocount on
   declare @cnt int
   declare @retVal int
   declare @TN1 char(120)
   declare @sql nvarchar(4000)
   declare @dbname varchar(130)
     
   -- see if the group is in use by users (most likely case)
   select  @cnt = count(*)  from USRGPMEM where GROUP_KEY = @userGroupKey
   if @cnt > 0
   begin
      -- return true if used
      set @retVal = 1
      select @retVal as retVal
      return @retVal
   end

   -- outer cursor to loop thru databases as found in CFLDRINFO 
   declare outercurs  cursor fast_forward 
        for select distinct DB_NAME  from CFLDRINFO
   open outercurs
   fetch next from outercurs into @dbname
   while @@fetch_status = 0
   begin

	   -- see if the group is in use by anything else in this database
	   declare curs1  cursor fast_forward 
	        for select TABLENAME from dbo.absp_Util_GetTableList('User.Info')
	   open curs1
	   fetch next from curs1 into @TN1
	   while @@fetch_status = 0
	   begin
		  set @sql = 'select @cnt = count(*) FROM [' + ltrim(rtrim(@dbname)) + '].dbo.' + ltrim(rtrim(@TN1)) + ' where STATUS <> ''DELETED'' and GROUP_KEY = ' + ltrim(rtrim(str(@userGroupKey)))
		  execute sp_executesql @sql, N'@cnt int output',@cnt output
	      if @cnt > 0
	      begin
	          -- return true if used
	         set @retVal = 1
	         select @retVal as retVal
	         return @retVal
	      end
	      fetch next from curs1 into @TN1
	   end
	   close curs1
	   deallocate curs1

   	fetch next from outercurs into @dbname
       
   -- close outer cursor
   end
   close outercurs
   deallocate outercurs

  -- return false if not used
   set @retVal = 0
   select @retVal as retVal
   return @retVal
end


