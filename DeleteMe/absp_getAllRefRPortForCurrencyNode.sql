if exists(select * from SYSOBJECTS where id = object_id(N'absp_getAllRefRPortForCurrencyNode') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_getAllRefRPortForCurrencyNode
end
go

create procedure absp_getAllRefRPortForCurrencyNode @ret_rprtnodlist varchar(MAX) output ,@curr_key int ,@port_key int ,@node_type int = 3 
-- This procedure will return a comma delimited list of all the rport_keys those are underneath the currency node key
-- that is passed as an argument to the procedure.  Rewritten for defect SDG__00010888 and SDG__00010894
-- SDG__00013513 -- use table CURRMAP to build the list instead of slower absp_FindNodeCurrencyKey.
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return a string containing a list of all rport node keys under a currency node 
excluding the rport node key passed as an input parameter in an OUTPUT parameter.

Returns:         Nothing


====================================================================================================
</pre>
</font>
##BD_END

##PD  @ret_rprtnodlist ^^ A string containing the list of rport node keys.
##PD @curr_key ^^  The key of the currency node for which the child rports need to be identified. 
##PD @port_key ^^  The rport node key that is excluded from the list of returned rports.
##PD @nodeType ^^  The node type, default to RportNode = 3.  

*/
as
begin
 
   set nocount on
   
  declare @portKeyList varchar(MAX)
   declare @rprt_type int
   declare @sqlQry varchar(max)
   set @rprt_type = @node_type
   if(@port_key > 0)
   begin
        execute @rprt_type = absp_Util_GetRPortType @port_key
   end
  
   set @sqlQry = 'select child_key from CURRMAP where FOLDER_key = '+rtrim(ltrim(str(@curr_key)))+' and child_key <> '+rtrim(ltrim(str(@port_key)))+' and child_type = '+str(@rprt_type)
   execute absp_util_genInListString @portKeyList output, @sqlQry
   set @ret_rprtnodlist = @portKeyList
end


