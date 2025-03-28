if exists ( select 1 from sysobjects where name = 'absp_Util_ExecSqlInChunks ' and type = 'P' )
begin
   drop procedure absp_Util_ExecSqlInChunks;
end
go

CREATE Procedure absp_Util_ExecSqlInChunks @sqlStr varchar(2000)
/*
 ##BD_BEGIN
 <font size ="3">
 <pre style="font-family: Lucida Console;" >
 ====================================================================================================
 DB Version:    MSSQL
 Purpose:

	This procedure runs the delete/update statement passed in sqlStr 32K rows at a time. Improves the
	performance of large queries.

 Returns: Nothing

 ====================================================================================================

 </pre>
 </font>
 ##BD_END

 ##PD  @sqlStr ^^  sql statement to be run in 32K rows at a time.

*/

as
begin try
	declare @sql varchar(2000);
	declare @cmd varchar(10);
	declare @sleepTime int;
	declare @topStr varchar(80);

	set @sleepTime = 100;				-- Sleep time in milli-seconds between each delete

	 -- use smaller chunk size for results db since this works better for blobs
	 if exists(select 1 from RQEVersion where DbType = 'EDB')
     begin
     	-- Parentheses that delimit expression in TOP are required.
     	-- The maximum value expression can be is 2147483648
        set @topStr = ' top (327670) ';
     end
     else
     begin
		set @topStr = ' top (1000) ';
	 end


	if patindex('%top%', @sqlStr) = 0
	begin
		set @cmd = substring(ltrim(@sqlStr), 1, 6);
		set @sql = @cmd +  @topStr + substring(ltrim(@sqlStr), 7, 2000);
	end
	else
	begin
		set @sql = @sqlStr;
	end

	while 1=1
	begin

        begin tran;
        execute(@sql);

        if @@rowcount <= 0
		begin
            break;
        end
        commit tran;

		if @sleepTime > 0
		begin
			exec absp_Util_Sleep @sleepTime ;
		end

	end -- while

	commit tran; -- for last iteration of loop

END TRY

BEGIN CATCH;
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH;
