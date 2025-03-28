if exists(SELECT * from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribGetGeneric') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribGetGeneric;
end
go

create procedure absp_InfoTableAttribGetGeneric  @setting bit out, @nodeType integer, @nodeKey integer, @attribName varchar(25), @databaseName varchar(120) =''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure gets the attribute setting for the given node and @attribName and returns it in an
     output parameter.


Returns: The attribute setting in an output parameter.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @setting ^^ The setting of the attrib   (Output parameter).(0 = Off or 1 = On)
##PD  @nodeType ^^ The type of node
##PD  @nodeKey ^^ The key of node for which the info attribute setting is to be seen
##PD  @attribName ^^ The attribute name to be search from the attrdef table.
*/
as
begin

	set nocount on;

	declare @attribute  varchar(25);


	declare @TableVar table (ATTRIBUTE varchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS, SETTING bit);
	insert into @TableVar exec absp_InfoTableAttribAllGet  @nodeType, @nodeKey, @databaseName;

	select @setting = SETTING  from @TableVar where ATTRIBUTE = @attribName;
	
end
