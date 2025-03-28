if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribSetWBUMode') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribSetWBUMode
end
go
 
create procedure absp_InfoTableAttribSetWBUMode  @nodeType integer, @nodeKey integer, @setting bit   
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure sets the 'WBU_Imported' Attribute for the given node with the given value.
     
    	    
Returns: Nothing.
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @nodeType ^^ The type of node for which the Invalidating attribute setting are to be set
##PD  @nodeKey ^^  The key of node for which the Invalidating attribute setting are to be set
##PD  @setting ^^ The setting of the Invalidating attribute .(0 = Off or 1 = On) 


*/
as
begin
    set nocount on
    declare @attribName  varchar(25)
    
	set @attribName = 'WBU_Imported'
	
	exec absp_InfoTableAttrib_Set @nodeType,@nodeKey,@attribName,@setting 
end
