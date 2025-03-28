if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_IsEqeDB') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Util_IsEqeDB
end
go

create procedure absp_Util_IsEqeDB 
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:

This PROCEDURE checks if the current database is a WCe/Eqe database or an Archive created
database or any other Database

Returns:       Returns 1 if the current database is a WCe/Eqe database; 0 if the current database is other than WCe/Eqe or Archive Database.

====================================================================================================

</pre>
</font>
##BD_END

##RD  ret_DBName ^^ 1 if current database is a WCe/Eqe database; 0 if current database other than WCe/Eqe or Archive Database.

*/
as
begin

	set nocount on

	--  This procedure will check if the current database is a WCe/Eqe database or an Archive created database
	--  Returns 1 if it is a WCe/Eqe database 
	--  Returns 0 if it is not a WCe/Eqe database and we assume it is an Archive created database
	declare @ret_DBName int
	declare @dbpath varchar(255)
	declare @sql nvarchar(255)
	
	set @ret_DBName = 0
	
	-- get dbfile name
	select @dbpath = physical_name from sys.database_files where file_id = 1

	-- check dbfile name
	if(select charindex('EQE.MDF',@dbpath)) > 0
	begin
		set @ret_DBName = 1
	end
	else
	begin
		if(select charindex('EQERESULTS.MDF',@dbpath)) > 0
		begin
			set @ret_DBName = 1
		end
	end

	return @ret_DBName
end
