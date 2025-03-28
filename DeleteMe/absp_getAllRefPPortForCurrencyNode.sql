if exists(select * from SYSOBJECTS where id = object_id(N'absp_getAllRefPPortForCurrencyNode') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_getAllRefPPortForCurrencyNode
end
 go
create procedure absp_getAllRefPPortForCurrencyNode @ret_portKeyList varchar(MAX) output, @curr_key int ,@port_key int 

-- This procedure will return a comma delimited list of all the pport_keys those are underneath the currency node key
-- that is passed as an argument to the procedure.  Rewritten for defect SDG__00010888 and SDG__00010894
-- SDG__00013513 -- use table CURRMAP to build the list instead of slower absp_FindNodeCurrencyKey.
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return a string containing a list of all pport node keys under a currency node 
excluding the pport node key passed as an input parameter in an OUTPUT parameter.

Returns:         Nothing.


====================================================================================================
</pre>
</font>
##BD_END

##PD @ret_portKeyList^^ List of pport node keys.
##PD curr_key ^^  The key of the currency node for which the child pports need to be identified. 
##PD port_key ^^  The pport node key that is excluded from the list of returned pports. 


*/
as
begin

   set nocount on
   
   declare @portKeyList varchar(MAX)
   declare @sql varchar(max)
   set @sql = 'select child_key from CURRMAP where FOLDER_key = '+rtrim(ltrim(str(@curr_key)))+' and child_key <> '+rtrim(ltrim(str(@port_key)))+' and child_type = 2 order by child_key'
   execute absp_util_genInListString @portKeyList output, @sql
   set @ret_portKeyList = @portKeyList
end



