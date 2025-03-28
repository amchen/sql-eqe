if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_AttachDatabase_RS') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_AttachDatabase_RS;
end
go

create procedure absp_Util_AttachDatabase_RS
    	@databaseName varchar(255),
	@dbPath varchar(254),
	@dbLogPath varchar(254),
	@attachNoLog int = 0

/*
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure calls the absp_Util_AttachDatabase and return the resultset to satisfy Hibernate

Returns:      status and message
====================================================================================================

##PD  @databaseName ^^  database name
##PD  @dbPath ^^  full database path excluding the database name
##PD  @dbLogPath ^^  full log file path excluding the database name
*/
AS
begin

	set nocount on;
	declare @message as varchar(1000);
	declare @status int
	exec @status = absp_Util_AttachDatabase @message out, @databaseName, @dbPath, @dbLogPath, @attachNoLog;
	select @status as Status, @message as Message;

end
