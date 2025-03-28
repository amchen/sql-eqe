if exists ( select 1 from sysobjects where name = 'absp_CleanupDeleter ' and type = 'P' ) 
begin
   drop procedure absp_CleanupDeleter  ;
end

go

CREATE Procedure absp_CleanupDeleter @deleteStr varchar(2000)
/*
 ##BD_BEGIN
 <font size ="3"> 
 <pre style="font-family: Lucida Console;" > 
 ====================================================================================================
 DB Version:    MSSQL
 Purpose:		

	This procedure runs the delete statement passed in deleteStr 32K rows at a time. Improves the
	performance of large deletes.	
 
 Returns: Nothing
               
 ====================================================================================================
 
 </pre>
 </font>
 ##BD_END
 
 ##PD  @deleteStr ^^  delete statement to be run in 32K rows at a time. 
*/

as
begin
	declare @sql varchar(2000);
	declare @sleepTime int;
		
	set @sleepTime = 100;				-- Sleep time in milli-seconds between each delete	
	set @sql = 'delete top (32767) ' + substring(ltrim(@deleteStr), 7, 2000);
	
	while 1=1
	begin
        execute(@sql);

        if @@rowcount <= 0 
		begin
            break;
        end 
        
		if @sleepTime > 0 -- is this needed for SQLServer? 
		begin
			exec absp_Util_Sleep @sleepTime ;
		end 

	end -- while
	
end
