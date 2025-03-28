
if exists(select * from SYSOBJECTS where ID = object_id(N'absp_TreeviewProgramsList') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewProgramsList
end
 go

create procedure 
absp_TreeviewProgramsList @rportKey int 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return a result set giving the name and key of each Program associated with a given RPortfolio.
It also gives back a PORT_ID so we know if it?s been imported


Returns:       A result set with three parameters:
1. CHILD_KEY	the PROG_KEY for each Program
2. LONGNAME	the name associated with each Program
3. LPORT_KEY	The LPORT_KEY of the logical portfolios underneath, in this case the PORT_ID for each Program

====================================================================================================
</pre>
</font>
##BD_END

##PD  @rportKey ^^  The RPORT_KEY of the Reinsurance Portfolio with which the program is associated.

##RS  PROG_KEY ^^  The PROG_KEY of each program.
##RS  LONGNAME ^^  The name associated with each program.
##RS  LPORT_KEY ^^  The LPORT_KEY of the logical portfolios underneath, in this case the PORT_ID of each program.


*/
begin

   set nocount on
   
   declare @rport_node_type int
   declare @prog_node_type int
  -- Based on the RPORT node type we can find out the program node_type since
  -- we cannot have a Multi-Treaty program under a Regular RPORT and vice-versa
   execute @rport_node_type = absp_Util_GetRPortType @rportKey
   
   if(@rport_node_type = 3)
   begin
      set @prog_node_type = 7
   end
   else
   begin
      if(@rport_node_type = 23)
      begin
         set @prog_node_type = 27
      end
   end
   select   RPORTMAP.CHILD_KEY as PROG_KEY, PROGINFO.LONGNAME as LONGNAME, PROGINFO.LPORT_KEY as LPORT_KEY from(PROGINFO join RPORTMAP on
   RPORTMAP.CHILD_KEY = PROGINFO.PROG_KEY) where
   RPORTMAP.RPORT_KEY = @rportKey and RPORTMAP.CHILD_TYPE = @prog_node_type order by
   PROGINFO.LONGNAME asc
end





