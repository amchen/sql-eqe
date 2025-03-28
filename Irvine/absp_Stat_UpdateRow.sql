if exists(select * from sysobjects WHERE id = object_id(N'absp_Stat_UpdateRow') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Stat_UpdateRow
end
go
create procedure absp_Stat_UpdateRow @operation_id int,@use_count int,@average_time float(24),@min_time float(24),@max_time float(24),@min_user_id int,@max_user_id int 
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	ASA
Purpose:	This procedure updates the STATTRAK table with given values for a given OPERATION_ID.

Returns:	Nothing
====================================================================================================

</pre>
</font>
##BD_END

##PD   	@operation_id 	^^ Request Id to track
##PD   	@use_count	^^ No of time the request was executed
##PD   	@average_time	^^ Average elapsed time recorded
##PD    @min_time         ^^ Minimum elapsed time recorded
##PD	@max_time      ^^ Maximum elapsed time recorded
##PD	@min_user_id  ^^ Id of the user who recorded the minimum time
##PD	@max_user_id  ^^ Id of the user who recorded the maximum time
*/
as
begin
   
   set nocount on
   
update STATTRAK set MIN_TIME = @min_time,MAX_TIME = @max_time,AVERAGE_TIME = @average_time,MIN_USER_ID = @min_user_id,MAX_USER_ID = @max_user_id,USE_COUNT = @use_count  where
   @operation_id = operation_id
end



