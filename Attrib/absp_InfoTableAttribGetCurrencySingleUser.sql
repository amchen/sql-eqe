if exists(SELECT * from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribGetCurrencySingleUser') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribGetCurrencySingleUser
end
go
 
create procedure absp_InfoTableAttribGetCurrencySingleUser  @setting bit out, @nodeKey integer 
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure gets the 'CF_SINGLE_USER_MODE' Attribute settings for the given currency node and returns it in an
     output parameter. 
     
    	    
Returns: The attribute setting in an output parameter.
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @setting ^^ The setting of the Currency node SingleUserMode attribute (Output parameter).(0 = Off or 1 = On) 
##PD  @nodeKey ^^  The key of node for which the Currency SingleUserMode attribute setting is to be seen

*/
as
begin
	
	set nocount on
	    
	declare @attribute  varchar(25)
	declare @attribName  varchar(25)
	declare @attribSetting  bit
		
	set @attribName = 'CF_SINGLE_USER_MODE'
		
	declare @TableVar table (ATTRIBUTE varchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS, SETTING bit)
	insert into @TableVar exec absp_InfoTableAttribAllGet  12, @nodeKey  
		
	select @setting = SETTING  from @TableVar where ATTRIBUTE = @attribName
end
