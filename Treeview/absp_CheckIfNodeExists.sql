if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CheckIfNodeExists') and objectproperty(id,N'isprocedure') = 1)
begin
   drop procedure absp_CheckIfNodeExists
end
 go

create procedure absp_CheckIfNodeExists @nodeName varchar(255),@nodeType int,@parentKey int = 0 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns the node key for a specified node name and type. For 'Case' nodes, the parentKey is
also specified as cases can have same names under different programs.


Returns:       It returns the node key for the given node name and type.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeName ^^  The longname of the node (portfolio) for which the node key is to be found.
##PD  @nodeType ^^  The type of node for which the node key is to be found.
##PD  @parentKey ^^  The key of parent node for which the node key is to be found.(Only for Case nodes).

##RD  @lastKey ^^  It returns the node key for the given node name and type. 
*/
as

begin

   set nocount on
	
   declare @nodeKey int;
   
   exec @nodeKey = absp_Util_GetNodeKeyByName @nodeName, @nodeType,@parentKey;
   
   select @nodeKey as NodeKey;   
end



