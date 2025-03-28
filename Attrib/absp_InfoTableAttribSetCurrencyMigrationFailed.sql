if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribSetCurrencyMigrationFailed') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribSetCurrencyMigrationFailed
end
go
 
create procedure absp_InfoTableAttribSetCurrencyMigrationFailed  @nodeKey integer, @setting bit   
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure sets the 'CF_MIGRATION_FAILED' Attribute for a currency node with the given value.
     
    	    
Returns: Nothing.
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @nodeKey ^^  The key of node for which the Currency migration attribute setting is to be set
##PD  @setting ^^ The setting of the Curreny Updating attribute .(0 = Off or 1 = On) 


*/
as
begin
    set nocount on
    declare @attribName  varchar(25)
    
	set @attribName = 'CF_MIGRATION_FAILED'
	
	exec absp_InfoTableAttrib_Set 12,@nodeKey,@attribName,@setting 
end