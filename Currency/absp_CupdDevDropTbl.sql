if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CupdDevDropTbl') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CupdDevDropTbl
end
 go

create procedure absp_CupdDevDropTbl

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:
This procedure drops the following currency update tables:-
CUPDINFO, CUPDCTRL, CUPDLOGS, CURRATIO, CUPDSTAT.

Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

*/
as
begin

   set nocount on
   
	   if exists(select  1 from sysobjects where name = 'CUPDINFO' and type = 'U')
	   begin
		  drop table CUPDINFO
	   end
	   if exists(select  1 from sysobjects where name = 'CUPDCTRL' and type = 'U')
	   begin
		  drop table CUPDCTRL
	   end
	   if exists(select  1 from sysobjects where name = 'CUPDLOGS' and type = 'U')
	   begin
		  drop table CUPDLOGS
	   end
	   if exists(select  1 from sysobjects where name = 'CURRATIO' and type = 'U')
	   begin
		  drop table CURRATIO
	   end
	   if exists(select  1 from sysobjects where name = 'CUPDSTAT' and type = 'U')
	   begin
		  drop table CUPDSTAT
	   end
end



