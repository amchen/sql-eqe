if exists ( select 1 from sysobjects where name =  'absp_Util_GetNodeNameByKey_RS' and type = 'P' ) 
begin
        drop procedure absp_Util_GetNodeNameByKey_RS ;
end
go

create procedure absp_Util_GetNodeNameByKey_RS @nodeKey int , @nodeType int ,  @extraKey1 int = 0, @extraKey2 int = 0
as
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure returns the node name for a specified node key and type. For policy, site and 
     case nodes,the extra keys are also specified.
     
    	    
Returns:       Nothing  
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @ret_NodeName   ^^ The node name for the given node key and type. 
##PD  nodeKey  ^^  The key of the node (portfolio) for which the node name is to be found.
##PD  nodeType ^^ The type of node for which the node name is to be found.
##PD  extraKey1 ^^ The parent progKey in case of case node and portId in case of policies & sites 
##PD  extraKey2 ^^  The parent policyKey in case of a site.

*/


BEGIN 

   set nocount on
   
   declare @nodeName varchar(max);
  
   exec absp_Util_GetNodeNameByKey @nodeName output, @nodeKey, @nodeType,  @extraKey1, @extraKey2
  
   select @nodeName as NodeName;
   
end;
