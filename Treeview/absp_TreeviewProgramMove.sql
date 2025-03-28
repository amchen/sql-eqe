if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewProgramMove') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_TreeviewProgramMove
end
 go
create procedure absp_TreeviewProgramMove @progKey int ,@currentRPortKey int ,@newRPortKey int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure moves a program from one parent rport node to another by changing the map entry in 
the RPORTMAP table.

Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  @progKey ^^  The key of the program that is to be moved.
##PD  @currentRPortKey ^^  The current parent rport key of the program that is to be moved.  
##PD  @newRPortKey ^^  The key of the rport under which the given program is to be moved. 

*/
as
begin
  
   set nocount on
   
-- this procedure will move a Program to a new RPortfolio parent
  -- update the map
   update RPORTMAP set RPORT_KEY = @newRPortKey  where
   RPORT_KEY = @currentRPortKey and
   CHILD_KEY = @progKey and(CHILD_TYPE = 7 or CHILD_TYPE = 27)
end

go


