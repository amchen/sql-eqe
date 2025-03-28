if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_AttachWCeDatabase_RS') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_AttachWCeDatabase_RS;
end
go

create procedure absp_Util_AttachWCeDatabase_RS
	@databaseName varchar(255),
	@groupKey int = 0,
	@userKey int = 1

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure calls the absp_Util_AttachDatabase and return the resultset to satisfy Hibernate

Returns:      status and message
====================================================================================================
</pre>
</font>
##BD_END

##PD  @@databaseName ^^  database name
##PD  @@groupKey ^^  group key
##PD  @@userKey ^^  user key
*/

AS
begin

	set nocount on;
	declare @message as varchar(1000);
	declare @status int
	exec @status = absp_Util_AttachWCeDatabase @message out, @databaseName, @groupKey, @userKey;
	select @status as Status, @message as Message;

end
