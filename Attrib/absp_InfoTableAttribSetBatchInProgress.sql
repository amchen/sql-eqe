if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribSetBatchInProgress') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribSetBatchInProgress;
end
go

create procedure absp_InfoTableAttribSetBatchInProgress @nodeKey integer, @nodeType int, @setting bit, @databaseName varchar(120) =''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure sets the 'BATCH_IN_PROGRESS' Attribute for a node with the given value.


Returns: Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeKey ^^  The key of node for which its Info Table attribute setting is to be set
##PD  @nodeType ^^ The type of node for which its Info Table attribute setting is to be set
##PD  @setting ^^ The setting of the batch In Progress attribute .(0 = Off or 1 = On)


*/
as
begin
    set nocount on;
    declare @attribName  varchar(25);

	set @attribName = 'BATCH_IN_PROGRESS';

	exec absp_InfoTableAttrib_Set @nodeType, @nodeKey, @attribName, @setting, @databaseName;
	select @setting
end
