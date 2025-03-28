if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_CheckForBatchJobs') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CheckForBatchJobs
end
go

create procedure absp_Util_CheckForBatchJobs @databaseName varchar(255)

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure checks for outstanding batch jobs for @databaseName 

Returns:     status = 0 for no batch jobs, else status = -1
====================================================================================================
</pre>
</font>
##BD_END

##PD  @@databaseName ^^  database name

##RD  @rc ^^ successful or error messages.
*/
AS
begin
	declare @status int

 	set nocount on
	set @status = 0

	if exists (select 1 from BatchJob where DBName = @databaseName and STATUS <> 'S' and STATUS <> 'F' and STATUS <> 'C')
	begin
		set @status = -1
	end
	
	-- Return a resultset to statisfy Hibernate
	select @status as status
	
	return @status
end



