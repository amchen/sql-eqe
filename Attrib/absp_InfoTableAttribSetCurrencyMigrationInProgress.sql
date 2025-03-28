if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribSetCurrencyMigrationInProgress') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribSetCurrencyMigrationInProgress
end
go
 
create procedure absp_InfoTableAttribSetCurrencyMigrationInProgress  @nodeKey integer, @setting bit, @databaseName varchar(120) = ''   
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure sets the 'CF_MIGRATION_IN_PROGRESS' Attribute for a currency node with the given value.
     
    	    
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
    
	set @attribName = 'CF_MIGRATION_IN_PROGRESS'
	
	if(@setting = 1)
	begin
		exec absp_InfoTableAttribSetCurrencyMigrationNeeded @nodeKey, 0, @databaseName
	end
	
	exec absp_InfoTableAttrib_Set 12,@nodeKey,@attribName,@setting, @databaseName 
end