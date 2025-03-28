if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_CheckIfTableExists') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CheckIfTableExists
end
go

create procedure absp_Util_CheckIfTableExists
	@TableName varchar(255)
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return an integer value based on whether or not a given table exists in an output parameter.
The table can be either a real table or a temp table. It returns 0 if table does not exists else 1.


Returns: An integer value
	 0,  If table does not exists
	 1,  If table does exists


====================================================================================================
</pre>
</font>
##BD_END 

##PD @TableName ^^  Name of the table to check

##RD @ret_status ^^ An integer value 0 if table does not exists, 1 if table does exists.

*/
as
begin
 
	set nocount on

	declare @ret_status int
	declare @SQL nvarchar(4000)
	
	-- Check if table exists
	begin try
		set @sql='select @ret_status= 1 from ' + @TableName
		execute sp_executesql @sql, N'@ret_status int out',@ret_status out
		set @ret_status = 1
	end try
	begin catch
		set @ret_status = 0;	
	end catch
	return @ret_status
	
end
