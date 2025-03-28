if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_BCPTableData') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Util_BCPTableData
end
go
create procedure absp_Util_BCPTableData @tableName varchar(1000), @inOutFlag char(5), @dataPath varchar(2000), @userName varchar(100) = '', @password varchar(100) = '' 
AS
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure load or unload a table depending on the parameters passed using BCP.


Returns: Nothing.

====================================================================================================
</pre>
</font>
##BD_END 

##PD  @tableName ^^ Table name which will be loaded or unloaded.
##PD  @inOutFlag ^^ If 'IN' is passed then table will be loaded and if 'OUT' is passed then table will be unloaded. 
##PD  @dataPath ^^ The specified path where data file will be placed .
##PD  @userName ^^ The userName - in case of SQL authentication
##PD  @password ^^ The password - in case of SQL authentication

##RD  @retVal  ^^ Nothing.

*/
begin

   set nocount on
   
   declare @authentication varchar(100)
   declare @sql nvarchar(4000)
   declare @dataFilePath varchar(8000)
   declare @uniqueKey int
   declare @indexScript nvarchar(4000)
   declare @tmpTableName varchar(100)
   
   set @dataPath = dbo.trim(replace(@dataPath, '/', '\'))
   print @dataPath

   set @tmpTableName = dbo.trim(@tableName)
   
   if CHARINDEX('_RESTR', @tableName) > 0
   begin
   	set @tmpTableName = dbo.trim(SUBSTRING(@tableName, 1, CHARINDEX('_RESTR', @tableName) - 1))
   end
   

   -- build dataFilePath and dataPath
   if CHARINDEX('.txt', @dataPath) > 0
    begin
		set @dataFilePath = @dataPath
		set @dataPath = left(@dataPath, len(@dataPath) - (CHARINDEX('\', REVERSE(@dataPath))-1))		
	end
	else
	begin
		exec absp_Util_GetDateString @uniqueKey output, 'hhnnss.sss'
		select  @uniqueKey = replace(@uniqueKey,'.','')
		set @dataFilePath = @dataPath + '\' + @tmpTableName + '_' +rtrim(ltrim(str(1000000000+@uniqueKey)))+ '.txt'
	end

   set @tableName = dbo.trim(@tableName)
   
   
   if len (@userName)>0 and len (@password)>0	
   	 	set @authentication = ' -U ' + @userName + ' -P ' + @password
   	else
   	 	set @authentication = ' -T'
   	
   	if (@inOutFlag = 'OUT')
   	begin 						
   		set @sql = 'bcp ["' + DB_NAME() + '"].dbo.' + @tableName + ' format nul -t -n -f "' + @dataPath + '\' + @tmpTableName + '.fmt" -t"" -E  -S ' + @@SERVERNAME + @authentication
   		execute absp_MessageEx @sql
   		exec xp_cmdshell @sql, no_output
   	end
   	
   	-- we should drop indices prior to loading data as this will increase loading performance
	if (@inOutFlag = 'IN')
   	begin
		if exists(select 1 from DICTTBL where TABLENAME = @tableName)
		begin
			-- drop all indicies
			execute absp_MessageEx 'dropping all indices'
			exec absp_Util_DropAllIndex @tableName
		end
		
		-- from 3.16 user lookup tables got renamed
		if(CHARINDEX(@tmpTableName, @dataFilePath) <= 0)
		begin
			set @tmpTableName = REPLACE(@tmpTableName, '_U', '')
		end
		
	end
	 		            
    set @sql = 'bcp ["' + DB_NAME() + '"].dbo.' + @tableName + ' ' + @inOutFlag + ' "' + @dataFilePath + '" -t -f "' + @dataPath + '\' + @tmpTableName + '.fmt" -E  -S ' + @@SERVERNAME + @authentication
   	execute absp_MessageEx @sql
    exec xp_cmdshell @sql

	execute absp_MessageEx 'bcp done'
	
	if (@inOutFlag = 'IN')
   	begin
		if exists(select 1 from DICTTBL where TABLENAME = @tableName)
		begin
			-- create all indicies
			execute absp_MessageEx 'creating all indices'
			exec absp_Util_CreateTableScript @indexScript output, @tableName, '', '', 2
			execute absp_MessageEx @indexScript
			if LEN(@indexScript) > 0
			begin
				exec sp_executesql @indexScript
			end
		end
	end

end

