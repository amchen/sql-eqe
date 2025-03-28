if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_CreateSysTable') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_Util_CreateSysTable;
end
go

create procedure absp_Util_CreateSysTable
	@baseTableName varchar(120),
	@newTableName varchar(120)
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose: This procedure will create a new table with the same schema/index as an existing base table.
Returns: 0 for success, 1 for failure.
====================================================================================================
</pre>
</font>
##FND_END

##PD  @baseTableName ^^ A string containing the name of the base table.
##PD  @newTableName  ^^ A string containing the name of the new table.
##RD  @retCode ^^ An integer value 0 on success and 1 on failure.
*/
AS
begin

	set nocount on;

	declare @baseTable varchar(120);
	declare @newTable  varchar(120);
	declare @retCode   integer;
	declare @sqlTbl    varchar(max);
	declare @retry    int;

	set @retry = 10;
	set @retCode = 1;
	set @baseTable = rtrim(ltrim(@baseTableName));
	set @newTable = rtrim(ltrim(@newTableName));

  	-- make sure the base table exists
	if exists(select 1 from SYS.TABLES where NAME = @baseTable) begin
		-- make sure the new table does not exist
		if not exists(select 1 from SYS.TABLES where NAME = @newTable) begin
            execute absp_Util_CreateSysTableScript @sqlTbl out, @baseTable,@newTable,'',1;
RetryLoop:
            begin try
         		execute(@sqlTbl);
				set @retCode = 0;
         	end try
         	begin catch
         		set @retCode = 1;
         		set @retry = @retry - 1;
         		if (@retry > 0)
         		begin
         			waitfor delay '00:00:01';
         			goto RetryLoop;
         		end
         	end catch
		end
	end
	return @retCode;
end
--exec absp_Util_CreateSysTable 'YLTPortData','YLTPortData_1'
