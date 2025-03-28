if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GenericTableMoveRecords') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GenericTableMoveRecords
end
go

create procedure absp_GenericTableMoveRecords
	@TmpTableName varchar(1000),
	@PermTableName varchar(1000),
	@ChunkSize int  = 10000,
	@debugFlag int = 1
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	MSSQL

Purpose:	This procedure is used by Chasie32.   It will move records from a temporary table
			to a permanent table.  
			
			Formerly, It performs the move in Chunks by removing the records
			from the temporary table after they are inserted into the permanent table.
			This is obsolete.   Now it just moves the all the records in one query.
			This is because a loop of
				insert into X select top (20) * from Y
				delete top (20) Y
			may fail.   The deleted 20 are not necessarily the same selected
			and inserted, so on another iteration an integrity violation occurs.


Returns:    Nothing

====================================================================================================

</pre>
</font>
##BD_END

##PD   @TmpTableName 	^^ Name of a Temporary table table that matches the permanent table (example IMPORT_CHASDATA_12345)
##PD   @PermTableName	^^ Name of the permanent table that will receive the records from @TmpTableName (example CHASDATA)
##RD   @ChunkSize     ^^ The number of records to copy and then delete from the temporary table
*/
as
begin

	set nocount on

	declare @sql varchar(MAX)
	declare @msgText varchar(MAX)

	set @sql =	'insert into ' + rtrim(@PermTableName) + 
				' select * from ' + rtrim(@TmpTableName)

	if(@debugFlag > 0)
	begin
		set @msgText = @sql
		execute absp_MessageEx @msgText
	end

	execute(@sql)




end
