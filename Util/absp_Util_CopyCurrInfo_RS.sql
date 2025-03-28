if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_CopyCurrInfo_RS') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CopyCurrInfo_RS
end
go

create procedure absp_Util_CopyCurrInfo_RS
    @sourceDb varchar(255),
    @destDb varchar(255)

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure copies currency, exchange rate, and user lookups from the source database to the 
destination database 

Returns:      successful or error messages
====================================================================================================
</pre>
</font>
##BD_END

##PD  @sourceDb ^^ copy exchrate data etc. from this database
##PD  @destDb ^^  to this database

*/
AS
begin
	set nocount on;
	declare @errMsg as varchar(1000);
	declare @status int
	exec @status = absp_Util_CopyCurrInfo @errMsg out, @sourceDb, @destDb;
	select @status as Status, @errMsg as ErrorMessage;
end