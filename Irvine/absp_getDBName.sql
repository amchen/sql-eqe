if exists(select * from SYSOBJECTS where ID = object_id(N'absp_getDBName') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_getDBName
end
go

create procedure  absp_getDBName  @ret_dbName varchar(130) output, @dbName varchar(130), @isIRDB int = 0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:
    This procedure will returns the given dbName enclosed within square brackets.
Returns:       Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @ret_dbName ^^  The databaseName enclosed within square brackets
##PD  @dbName ^^  The actual database name.
*/
as
begin

	set nocount on;

	set @ret_dbName = rtrim(@dbName);

	-- strip brackets
	set @ret_dbName = replace(@ret_dbName,'[','');
	set @ret_dbName = replace(@ret_dbName,']','');

	if (@isIRDB = 1)
	begin
		set @ret_dbName = @ret_dbName + '_IR';
	end

	set @ret_dbName = QUOTENAME(@ret_dbName);
end
