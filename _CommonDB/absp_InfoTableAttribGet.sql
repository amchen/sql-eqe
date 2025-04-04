if exists(SELECT * from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribGet') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribGet
end
go
 
create procedure absp_InfoTableAttribGet  @setting bit out, @nodeKey integer, @attribName  varchar(25)
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure gets the given Attribute settings for the given currency node and returns it in an
     output parameter. 
     
    	    
Returns: The attribute setting in an output parameter.
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @setting ^^ The setting of the Currency node migration attribute (Output parameter).(0 = Off or 1 = On) 
##PD  @nodeKey ^^  The key of node for which the Currency migration attribute setting is to be seen
##PD  @attribName ^^  The attribute setting is to be seen


*/
as
begin
	
	set nocount on
	    
	declare @attribute  varchar(25)
	declare @attribSetting  bit
			
	declare @TableVar table (ATTRIBUTE varchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS, SETTING bit)
	insert into @TableVar exec absp_InfoTableAttribAllGet  12, @nodeKey  
		
	select @setting = SETTING  from @TableVar where ATTRIBUTE = @attribName
end
