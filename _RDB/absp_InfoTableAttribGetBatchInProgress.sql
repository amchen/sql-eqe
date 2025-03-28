if exists(SELECT * from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribGetBatchInProgress') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribGetBatchInProgress;
end
go

create procedure absp_InfoTableAttribGetBatchInProgress  @nodeType integer, @nodeKey integer, @databaseName varchar(120) =''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure gets the 'BATCH_IN_PROGRESS' Attribute settings for the given node and returns (0 = Off or 1 = On)

Returns: The attribute setting in an output parameter.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeType ^^ The type of node
##PD  @nodeKey ^^ The key of node for which the info attribute setting is to be seen
##PD  @databaseName ^^ The name of the database where the info table resides
*/
as
begin

	set nocount on;

	declare @attribName  varchar(25);
	declare @setting int;

	set @attribName = 'BATCH_IN_PROGRESS'

	declare @TableVar table (ATTRIBUTE varchar(25) COLLATE SQL_Latin1_General_CP1_CI_AS, SETTING bit);
	insert into @TableVar exec absp_InfoTableAttribAllGet  @nodeType, @nodeKey, @databaseName;

	select @setting = SETTING  from @TableVar where ATTRIBUTE = @attribName;
	
	if(@setting is null)set @setting = 0
	
	--return a result set to please jdbc stored proc execution
	select @setting as setting
end
