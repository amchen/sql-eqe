if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_CheckForDatabase') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CheckForDatabase
end
go

create procedure absp_Util_CheckForDatabase @dbName varchar(255)
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL

Purpose:	Check sys.databases for the specified database

Returns:        Returns 1 for database is attached to sql server and 0 if not.
====================================================================================================
</pre>
</font>
##BD_END

##PD	@dbName			^^  The name of the database to check for in sys.databases. 
##RD	@ret_status		^^  Returns 1 for database attached and 0 if not.

*/
as
begin

   	set nocount on
   
	declare @ret_status int
	
	set @ret_status = 0

	if exists (SELECT 1 FROM sys.databases where name = ltrim(rtrim(@dBName)))
	begin
	  set @ret_status = 1
	end

	return @ret_status
end

