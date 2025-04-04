if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribSetReplicated') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribSetReplicated
end
go
 
create procedure absp_InfoTableAttribSetReplicated   @nodeType integer, @nodeKey integer, @setting bit   
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure sets the 'REPLICATED' Attribute for the given node with the given value.
     
    	    
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
	set @attribName = 'REPLICATED'
	
	exec absp_InfoTableAttrib_Set @nodeType,@nodeKey,@attribName,@setting 
end