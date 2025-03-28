if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribSetAvoidZurZone4') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribSetAvoidZurZone4
end
go
 
create procedure absp_InfoTableAttribSetAvoidZurZone4  @nodeKey integer, @setting bit   
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure sets the 'CF_SINGLE_USER_MODE' Attribute for a currency node with the given value.
     
    	    
Returns: Nothing.
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @nodeKey ^^  The key of node for which the Currency SingleUserMode attribute setting is to be set
##PD  @setting ^^ The setting of the Curreny SingleUserMode attribute .(0 = Off or 1 = On) 


*/
as
begin
    set nocount on
    declare @attribName  varchar(25)
    
	set @attribName = 'AvoidZurZone4'
	
	exec absp_InfoTableAttrib_Set 64,@nodeKey,@attribName,@setting 
end