if exists(select * from sysobjects where id = object_id(N'absp_MoveDoneDatesBackSubr') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_MoveDoneDatesBackSubr
end

go
create procedure absp_MoveDoneDatesBackSubr @tableName char(120),@fieldName char(120),@origDate char(8) = '',@daysBack int = 30,@debug int = 0 
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    SQL2005
Purpose:       This procedures set date field passed as parameter to prior date by given daysback
	       of given tablename.
     
    	    
Returns:       Nothing 

====================================================================================================
</pre>
</font>
##BD_END 

##PD  @tableName ^^  The tablename from which days will be back
##PD  @fieldName ^^  The date field of specified table
##PD  @origDate ^^  The original date which is stroed in date field
##PD  @daysBack ^^  The number of days to be backed from origDate
##PD  @debug ^^  A flag to determine whether message will be displayed or not

*/
as
begin
   declare @sSql varchar(max)
   declare @formattedValue varchar(max)
   declare @fieldValue varchar(max)
   declare @newDate datetime
   
   if @origDate = ''
      exec absp_Util_GetDateString @origDate output, 'yyyymmdd'

   if @debug > 0
      execute absp_MessageEx 'absp_MoveDoneDatesBackSubr start'

   -- the goal is to set a dae field to a prior date by xx days
-- sample sSql result of the below
-- update LOGS set START_TIME =  
-- dateformat ( cast ( left ( START_TIME, 8) + ' ' + 
-- substr ( START_TIME,  9, 2) + ':'  + substr ( START_TIME, 11, 2) + 
-- ':'  + substr ( START_TIME, 13, 2)   as timestamp ) - 99, 'yyyymmddhhnnss' )
-- where left ( START_TIME, 8) = '20041015'

   set @sSql = 'select ' + rtrim(ltrim(@fieldName)) +' from ' +rtrim(ltrim(@tableName)) + ' where left ( '+rtrim(ltrim(@fieldName))+', 8) = '+''''+ rtrim(ltrim(@origDate))+''''
   execute('declare curs_datesBack cursor global for '+ @sSql) 
   open curs_datesBack
   fetch next from curs_datesBack into @fieldValue
   while @@fetch_status = 0
   begin
   set @newDate = cast ( left ( @fieldValue, 8) + ' ' + substring ( @fieldValue,  9, 2) + ':'  + substring ( @fieldValue, 11, 2) + ':'  
				+ substring ( @fieldValue, 13, 2)   as datetime ) - @daysBack

   exec absp_Util_GetDateString @formattedValue output , 'yyyymmddhhnnss', @newDate
   set @sSql = 'update '+rtrim(ltrim(@tableName))+' set '+rtrim(ltrim(@fieldName))+' = ' + @formattedValue + 
				  'where left ( '+rtrim(ltrim(@fieldName))+', 8) = '+''''+rtrim(ltrim(@origDate))+''''
 
   execute(@sSql)
   fetch next from curs_datesBack into @fieldValue
   end
   close curs_datesBack  
   deallocate curs_datesBack

   if @debug > 0
      execute absp_MessageEx @sSql
   
   
end



