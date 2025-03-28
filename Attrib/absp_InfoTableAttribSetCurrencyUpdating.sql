if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribSetCurrencyUpdating') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribSetCurrencyUpdating
end
go
 
create procedure absp_InfoTableAttribSetCurrencyUpdating  @nodeType integer, @nodeKey integer, @setting bit   
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure sets the 'CURRENCY_UPDATING' Attribute for the given node with the given value.
     
    	    
Returns: Nothing.
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @nodeType ^^ The type of node for which the Curreny Updating attribute setting are to be set
##PD  @nodeKey ^^  The key of node for which the Curreny Updating attribute setting are to be set
##PD  @setting ^^ The setting of the Curreny Updating attribute .(0 = Off or 1 = On) 


*/
as
begin
    set nocount on
    declare @attribName  varchar(25)
    
	set @attribName = 'CURRENCY_UPDATING'
	
	if @nodeType = 12
		select @nodeKey = CF_REF_KEY from FLDRINFO where CURR_NODE = 'Y' and FOLDER_KEY = @nodeKey
	
	exec absp_InfoTableAttrib_Set @nodeType,@nodeKey,@attribName,@setting 
end
 