

if exists(select * from SYSOBJECTS where ID = object_id(N'absp_BaseCaseSet') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_BaseCaseSet
end
 go
create procedure absp_BaseCaseSet @progKey int ,@caseKey int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure sets the base case of a given program.

Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @progKey ^^  The key of the program for which the base case is to be set.
##PD  @caseKey ^^  The key of the case which is to be set as the base case of the given program.  

*/
as
begin
  
   set nocount on
   
 update PROGINFO set BCASE_KEY = @caseKey  where
   PROG_KEY = @progKey
end


