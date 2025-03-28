if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Stat_GetAll') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Stat_GetAll
end
go

create procedure absp_Stat_GetAll as
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure returns a single resultset containing all the records of STATTRAK table.

Returns:	A single resultset containing all the records of STATTRAK table

====================================================================================================

</pre>
</font>
##BD_END

##RS   	OPERATION_ID 	^^ Request Id to track.
##RS   	AVERAGE_TIME	^^ Average elapsed time recorded.
##RS   	MAX_TIME	^^ Max Time.
##RS    MIN_TIME        ^^ Min Time
##RS	USE_COUNT       ^^ Number of times the request was executed.
##RS	OPERATION_NAME  ^^ Request Name.
##RS	MAX_USER_ID  ^^ Id of the User who recorded the max time.
##RS	MIN_USER_ID  ^^ Id of the User who recorded the min time.

*/
begin

   set nocount on
   
   select   OPERATION_ID as OPERATION_ID, AVERAGE_TIME as AVERAGE_TIME, MAX_TIME as MAX_TIME, MIN_TIME as MIN_TIME, USE_COUNT as USE_COUNT, OPERATION_NAME as OPERATION_NAME, MAX_USER_ID as MAX_USER_ID, MIN_USER_ID as MIN_USER_ID from STATTRAK
end



