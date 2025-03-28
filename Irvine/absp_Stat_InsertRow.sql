if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Stat_InsertRow') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Stat_InsertRow
end

go

create procedure absp_Stat_InsertRow @operation_id int ,@operation_name varchar(25) ,@min_time float(24) = 0.0 ,@max_time float(24) = 0.0 ,@average_time float(24) = 0.0 ,@use_count int = 0 ,@min_user_id int = -1 ,@max_user_id int = -1  
as
/* 
##BD_BEGIN  
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose: 

This procedure updates the STATTRAK table with given values for a given OPERATION_ID
if it already exists in the table else inserts a new record.

Returns:       Zero
=================================================================================
</pre> 
</font> 
##BD_END 

##PD  @operation_id ^^ Request Id to track.
##PD  @operation_name  ^^ Request Name
##PD  @min_time ^^ Minimum elapsed time recorded.
##PD  @max_time ^^ Maximum elapsed time recorded
##PD  @average_time ^^ Average elapsed time recorded
##PD  @use_count ^^ No of time the request was executed
##PD  @min_user_id ^^ Id of the user who recorded the minimum time
##PD  @max_user_id ^^ Id of the user who recorded the maximum time

##RD @retVal ^^ Zero.

*/
begin
 
   set nocount on
   
  declare @retVal int
begin try
      insert into
      STATTRAK(OPERATION_ID,OPERATION_NAME,MIN_TIME,MAX_TIME,AVERAGE_TIME,MIN_USER_ID,MAX_USER_ID,USE_COUNT) values(@operation_id,@operation_name,@min_time,@max_time,@average_time,@min_user_id,@max_user_id,@use_count)
end try
begin catch
      update STATTRAK set MIN_TIME = @min_time,MAX_TIME = @max_time,AVERAGE_TIME = @average_time,MIN_USER_ID = @min_user_id,MAX_USER_ID = @max_user_id,USE_COUNT = @use_count,OPERATION_NAME = @operation_name  where
      @operation_id = OPERATION_ID
end catch
set @retVal = 0    
return @retVal
end


