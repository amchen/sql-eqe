if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CupdLogMessage') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CupdLogMessage
end
 go

create procedure absp_CupdLogMessage @cupdKey int,@eLevel char(1),@msg varchar(255),@genericFieldName char(80) = '',@genericFieldValue int = 0 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:
This procedure inserts a log record in the CUPDLOGS table.

Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  @cupdKey ^^  The currency update key. 
##PD  @eLevel ^^  The severity level.
##PD  @msg ^^  Text for the message.
##PD  @genericFieldName ^^  The field name for which the log record is created.
##PD  @genericFieldValue ^^  The value of the field for which the log record is created..

*/
as

begin

   	set nocount on
   	declare @createDt char(20)
   	exec absp_Util_GetDateString @createDt output,'yyyymmddhhnnss'
	insert into CUPDLOGS(CUPD_KEY,DATE_TIME,ELEVEL,GENKEYFLD,GENKEYVAL,MSG_TEXT) values(@cupdKey,@createDt,@eLevel,@genericFieldName,@genericFieldValue,@msg)
end