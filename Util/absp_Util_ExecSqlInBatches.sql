if exists ( select 1 from sysobjects where name = 'absp_Util_ExecSqlInBatches' and type = 'P' ) 
begin
   drop procedure absp_Util_ExecSqlInBatches  ;
end

go



CREATE Procedure absp_Util_ExecSqlInBatches @sqlStr varchar(2000)
/*
 
 ====================================================================================================
 DB Version:    MSSQL
 Purpose:		

	This procedure executes sqlStr 32K rows at a time. Improves the
	performance of large queries. 	
 
 Returns: the count of rows affected
               
 ====================================================================================================
*/

as
begin
	declare @sql varchar(2000);
	declare @cmd varchar(10);
	declare @sleepTime int;
	declare @topStr varchar(80);
	declare @countRows int;
	
	
	set @countRows=0;	
	set @sleepTime = 100;				-- Sleep time in milli-seconds between each execution	
	
	 -- use smaller chunk size for results db since this works better for blobs 
	 if exists(select 1 from RQEVersion where DbType = 'EDB')
     begin
        set @topStr = ' top (32767) ';
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
	
        begin transaction;
        execute(@sql);

        if @@rowcount <= 0 
		begin
            break;
        end 
        set @countRows = @countRows + @@rowcount;
        commit;
        
		if @sleepTime > 0 
		begin
			exec absp_Util_Sleep @sleepTime ;
		end 

	end -- while
	
	commit; -- for last iteration of loop
	return @countRows;
	
END
GO


