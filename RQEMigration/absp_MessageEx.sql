if exists(select * from sysobjects where ID = object_id(N'absp_MessageEx') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
	drop procedure absp_MessageEx
end
go

create procedure absp_MessageEx
	@msg varchar(max),
	@dtTmStamp bit = 1

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:	This Procedure calls another Stored Procedure, that in turn logs a message into a Log File.
====================================================================================================
</pre>
</font>
##BD_END

##PD   @msg 		^^ Any Message as Input Parameter
##PD   @dtTmStamp	^^ TimeStamp as Input Parameter
*/

as
begin
	set nocount on;

--------------------------------------------
-- Uncomment the section below for debugging
--------------------------------------------
/*
declare @msg2 varchar(max);
declare @context int;
set @context = cast(context_info() as int);
set @msg2 = 'BatchJobKey=' + cast(@context as varchar) + ': ' + @msg;
exec dbo.absxp_LogIt 'C:/Temp/EDB_debug.log', @msg2;
*/
--------------------------------------------

	execute absp_Util_LogIt @msg, 1, 'Unknown';
end
