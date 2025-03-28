if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribSetReadOnly') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribSetReadOnly
end
go
 
create procedure absp_InfoTableAttribSetReadOnly  @nodeType integer, @nodeKey  integer, @setting bit   
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure sets the 'READ_ONLY' Attribute for the given node with the given value.
     
    	    
Returns: Nothing
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @nodeType ^^ The type of node for which the Read_Only attribute setting are to be set
##PD  @nodeKey ^^  The key of node for which the Read_Only  attribute setting are to be set
##PD  @setting ^^ The setting of the Read_Only  attribute .(0 = Off or 1 = On) 


*/
as
begin
    
    set nocount on
    declare @attribName  varchar(25)
	set @attribName = 'READ_ONLY'
	
	exec absp_InfoTableAttrib_Set @nodeType,@nodeKey,@attribName,@setting 
end