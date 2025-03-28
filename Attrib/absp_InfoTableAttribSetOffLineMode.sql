if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_InfoTableAttribSetOffLineMode') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InfoTableAttribSetOffLineMode;
end
go

create procedure absp_InfoTableAttribSetOffLineMode  @nodeKey integer, @setting bit, @databaseName varchar(120) =''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure sets the 'DB_OFFLINE_MODE' Attribute for a currency node with the given value.


Returns: Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeKey ^^  The key of node for which the Currency COPYING attribute setting is to be set
##PD  @setting ^^ The setting of the Curreny copying attribute .(0 = Off or 1 = On)


*/
as
begin
    set nocount on;
    declare @attribName  varchar(25);

	set @attribName = 'DB_OFFLINE_MODE';

	exec absp_InfoTableAttrib_Set 12, @nodeKey, @attribName, @setting, @databaseName;
end
