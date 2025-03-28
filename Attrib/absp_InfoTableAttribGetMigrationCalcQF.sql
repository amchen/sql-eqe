if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribGetMigrationCalcQF') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribGetMigrationCalcQF
end
go
 
create procedure absp_InfoTableAttribGetMigrationCalcQF @setting bit output, @nodeType integer, @nodeKey integer   
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure gets the 'CF_MIGRATION_CALQF' Attribute settings for the given node and returns it in an
     output parameter. 
     
    	    
Returns: The attribute setting in an output parameter.
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @setting ^^ The setting of the Invalidaing attribute (Output parameter).(0 = Off or 1 = On) 
##PD  @nodeType ^^ The type of node for which the Invalidaing attribute setting are to be seen
##PD  @nodeKey ^^  The key of node for which the Invalidaing attribute setting are to be seen

*/
as
begin

    set nocount on
    
    declare @attribute  varchar(25)
	declare @attribName  varchar(25)
	declare @attribSetting  bit
	
	set @attribName = 'CF_MIGRATION_CALQF'
	
	declare @TableVar table (ATTRIBUTE varchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS, SETTING bit)
	insert into @TableVar exec absp_InfoTableAttribAllGet  @nodeType , @nodeKey  
	
	select @setting = SETTING  from @TableVar where ATTRIBUTE = @attribName
	
	select @setting as MigrationCalcQF
end

