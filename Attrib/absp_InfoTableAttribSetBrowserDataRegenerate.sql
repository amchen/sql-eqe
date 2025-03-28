if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribSetBrowserDataRegenerate') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribSetBrowserDataRegenerate
end
go
 
create procedure absp_InfoTableAttribSetBrowserDataRegenerate   @nodeType integer, @nodeKey integer, @setting bit   
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure sets the 'BRW_DATA_REGENERATE' Attribute for the given node with the given value.
     
    	    
Returns: Nothing
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @nodeType ^^ The type of node for which the Replicated attribute setting are to be set
##PD  @nodeKey ^^  The key of node for which the Replicated  attribute setting are to be set
##PD  @setting ^^ The setting of the Replicated  attribute .(0 = Off or 1 = On) 


*/

as
begin
    
    set nocount on
    declare @attribName  varchar(25)
	set @attribName = 'BRW_DATA_REGENERATE'
	
	exec absp_InfoTableAttrib_Set @nodeType,@nodeKey,@attribName,@setting 
end