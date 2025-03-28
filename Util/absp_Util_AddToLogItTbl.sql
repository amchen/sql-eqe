if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_AddToLogItTbl') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_AddToLogItTbl
end
 go

create procedure ----------------------------------------------------
absp_Util_AddToLogItTbl @proc_Name varchar(max) ,@logLevel int 
/*
##BD_BEGIN
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure inserts entries for the procedure names that matches the given proc_name param 
into LOGITTBL with the supplied logLevel.

Returns: Nothing

====================================================================================================

</pre>
</font>
##BD_END

##PD  @proc_name ^^ The procedure name to be inserted. It may be followed by wildcard character '--'.
##PD  @logLevel  ^^ The log level that is to be associated with procedure names.

*/
as
begin
 
   set nocount on
   
 /*

  This procedure will add all the procedure that matches the proc_name into LOGITTBL.
  Example,

  call absp_Util_AddToLogItTbl ('absp_Arc--', 3);

  This call will add all procedure that starts with "absp_Arc--" into LOGITTBL and set the LOG_LEVEL
  for each procedure to 3
  */
   declare @swv_Curs1_Procedure_Name varchar(255)
   declare @curs1 cursor
   begin transaction
   set @curs1 = cursor dynamic for select NAME as PROCEDURE_NAME from SYSOBJECTS where NAME like @proc_Name
   open @curs1
   fetch next from @curs1 into @swv_Curs1_Procedure_Name
   while @@fetch_status = 0
   begin
      insert into LOGITTBL(PROC_NAME,LOG_LEVEL) values(@SWV_curs1_procedure_name,@logLevel)
      fetch next from @curs1 into @swv_Curs1_Procedure_Name
   end
   close @curs1
   commit Transaction
end






