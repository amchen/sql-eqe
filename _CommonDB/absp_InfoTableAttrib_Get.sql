if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttrib_Get') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttrib_Get;
end
go

create procedure absp_InfoTableAttrib_Get   @nodeType integer,
											@nodeKey integer,
											@attributeName varchar(25),
											@databaseName varchar(125) = ''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure gets the attribute bit (1 or 0) of the related INFO table with the given AttributeName
     for the given Node.


Returns: Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeType ^^ The type of node for which the attribute is to be set
##PD  @nodeKey ^^  The key of node for which the attribute is to be set
##PD  @attributeName  ^^ The attribute which is to be set. It can be REPLICATE, READONLY, LOCKED, INVALIDATING
##PD  @databaseName ^^ The database name

*/

as
begin
	set nocount on;

	declare @setting int;
	declare @dbName varchar(125);

	if @databaseName = ''
		set @dbName = ltrim(rtrim(DB_NAME()));
	else
		set @dbName = ltrim(rtrim(@databaseName));

	--Enclose within square brackets
	execute absp_getDBName @dbName out, @dbName;

	exec absp_InfoTableAttribGetGeneric @setting output, @nodeType, @nodeKey, @attributeName, @dbName
	if(@setting is null)set @setting = 0
	
	select @setting as setting
end
