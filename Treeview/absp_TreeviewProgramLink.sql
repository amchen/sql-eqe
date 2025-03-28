if exists(select * from sysobjects where id = object_id(N'absp_TreeviewProgramLink') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewProgramLink
end
 go

create procedure absp_TreeviewProgramLink @progKey int ,@newRPortKey int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure paste links a given program residing under an rport to another given rport.

Returns:	Nothing

====================================================================================================
</pre>
</font>
##BD_END

##PD  progKey ^^  The key of the program which is to be linked.
##PD  newRPortKey ^^  The key of the parent rport to which the given program is to be linked.  

*/
AS
begin

   set nocount on
   
   declare @cntInstance int
   declare @prog_node_type int
   execute  @prog_node_type = absp_Util_GetProgramType @progKey
  -- first we need to see if this is the only instance
   select  @cntInstance = COUNT(*)  from RPORTMAP where
   RPORT_KEY = @newRPortKey and CHILD_KEY = @progKey and(CHILD_TYPE = 7 or CHILD_TYPE = 27)
   if @cntInstance = 0  and (@prog_node_type = 7 or @prog_node_type = 27)
   begin
      insert into RPORTMAP(RPORT_KEY,CHILD_KEY,CHILD_TYPE) values(@newRPortKey,@progKey,@prog_node_type)
   end
end
