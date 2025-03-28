if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribSetCurrencyCopyInProgress') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribSetCurrencyCopyInProgress
end
go
 
create procedure absp_InfoTableAttribSetCurrencyCopyInProgress  @nodeKey integer, @setting bit   
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure sets the 'CF_COPY_IN_PROGRESS' Attribute for a currency node with the given value.
     
    	    
Returns: Nothing.
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @nodeKey ^^  The key of node for which the Currency COPYING attribute setting is to be set
##PD  @setting ^^ The setting of the Curreny copying attribute .(0 = Off or 1 = On) 


*/
as
begin
    set nocount on
    declare @attribName  varchar(25)
    
	set @attribName = 'CF_COPY_IN_PROGRESS'
	
	exec absp_InfoTableAttrib_Set 12,@nodeKey,@attribName,@setting 
end

