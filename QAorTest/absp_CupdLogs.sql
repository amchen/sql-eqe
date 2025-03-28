if EXISTS(SELECT * FROM dbo.sysobjects WHERE id = object_id(N'absp_CupdLogs') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   DROP PROCEDURE absp_CupdLogs
end

go 
create procedure absp_CupdLogs 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:     SQL2005
Purpose:        This procedure returns resultset which contain records of errors and then last top 100 
                error records from CUPDLOGS for max(CUPD_KEY) of CUPDINFO.

Returns:        A single resultset which shows you errors first then the last top 100 records of CUPDLOGS. 

====================================================================================================

</pre>
</font>

##BD_END 

*/
as
begin
   declare @cupdKey INT
   select   @cupdKey = max(CUPD_KEY)  from CUPDINFO
   select CUPDLOGKEY, CUPD_KEY, DATE_TIME, ELEVEL, GENKEYFLD, GENKEYVAL, cast(MSG_TEXT as varchar) from CUPDLOGS where CUPD_KEY = @cupdKey and ELEVEL = 'E' 
   union
   select  top 100 CUPDLOGKEY, CUPD_KEY, DATE_TIME, ELEVEL, GENKEYFLD, GENKEYVAL, cast(MSG_TEXT as varchar) from CUPDLOGS where CUPD_KEY = @cupdKey order by 4 asc,1 desc
end

go

