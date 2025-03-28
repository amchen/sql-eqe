if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_DetachRQEDatabase_RS') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_DetachRQEDatabase_RS;
end
go

create procedure absp_Util_DetachRQEDatabase_RS
	@databaseName varchar(255),
	@forced int = 0,
	@longname varchar(255) = '',
	@dbPathPri varchar(254) = 'C:\RQEDatabases\UserDatabases\EDB',
	@dbPathIR varchar(254) = 'C:\RQEDatabases\UserDatabases\IDB',
	@dbLogPathPri varchar(254) = 'C:\RQEDatabases\UserDatabases\EDB',
	@dbLogPathIR varchar(254) = 'C:\RQEDatabases\UserDatabases\IDB'

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure calls the absp_Util_DetachWCeDatabase and return the resultset to satisfy Hibernate

Returns:      status and message
====================================================================================================
</pre>
</font>
##BD_END

##PD  @@databaseName ^^ database name
##PD  @@forced ^^
##PD  @@longname ^^
##PD  @@dbPathPri ^^
##PD  @@dbPathIR ^^
##PD  @@dbLogPathPri ^^
##PD  @@dbLogPathIR ^^
*/

AS
begin

	set nocount on;
	declare @message as varchar(1000);
	declare @status int
	exec @status = absp_Util_DetachWCeDatabase @message out, @databaseName, @forced, @longname, @dbPathPri, @dbPathIR, @dbLogPathPri, @dbLogPathIR;
	select @status as Status, @message as Message;

end
