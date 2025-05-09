if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribSetRDBMigrationNeeded') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribSetRDBMigrationNeeded
end
go
 
create procedure absp_InfoTableAttribSetRDBMigrationNeeded  @nodeKey integer, @setting bit, @rdbName varchar(120)     
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure sets the 'CF_MIGRATION_NEEDED' Attribute for a RDB node with the given value.
     
    	    
Returns: Nothing.
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @nodeKey ^^  The key of node for which the RDB migration attribute setting is to be set
##PD  @setting ^^ The setting of the RDB Updating attribute .(0 = Off or 1 = On) 


*/
as
begin
    set nocount on
    declare @attribName  varchar(25)
    
	set @attribName = 'CF_MIGRATION_NEEDED'

	if(@setting = 1)
	begin
		exec absp_InfoTableAttribSetRDBMigrationInProgress @nodeKey, 0, @rdbName
	end
	
	exec absp_InfoTableAttrib_Set 101,@nodeKey,@attribName,@setting, @rdbName 
end