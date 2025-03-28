if exists(SELECT * from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribGetGeneric_RS') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribGetGeneric_RS;
end
go

create procedure absp_InfoTableAttribGetGeneric_RS  @nodeType integer, @nodeKey integer, @attribName varchar(25), @databaseName varchar(120) =''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure gets the attribute setting for the given node and @attribName and returns it in an
     result set.


Returns: The attribute setting in an Result set.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeType ^^ The type of node
##PD  @nodeKey ^^ The key of node for which the info attribute setting is to be seen
##PD  @attribName ^^ The attribute name to be search from the attrdef table.
*/
as
begin

	set nocount on;

	declare @attribute  varchar(25);
	declare @setting bit


	exec absp_InfoTableAttribGetGeneric @setting out, @nodeType, @nodeKey, @attribName, @databaseName 
	
	select @setting as attribValue
	
end
