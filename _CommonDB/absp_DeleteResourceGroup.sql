if exists(select * from SYSOBJECTS where ID = object_id(N'absp_DeleteResourceGroup') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_DeleteResourceGroup
end
go

create procedure absp_DeleteResourceGroup @resourceGroupKey varchar(4000)
as
/* 
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose: 

The procedure deletes given ResourceGroup 

Returns:       None.

=================================================================================
</pre> 
</font> 
##BD_END 

*/
begin

   set nocount on
   
    declare @nsql nvarchar(max)
   
	set @nsql = N'update BatchJobSettings set ResourceGroupKey = 0 where ResourceGroupKey in (' + rtrim(@resourceGroupKey) + ');'
	
	set @nsql = @nsql + N'delete from ResourceGroupDetails where ResourceGroupKey in (' + rtrim(@resourceGroupKey) + ');' 
	
	set @nsql = @nsql + N'delete from ResourceGroupInfo where ResourceGroupKey in (' + rtrim(@resourceGroupKey) + ');' 
	
	exec sp_executesql @nsql
end
