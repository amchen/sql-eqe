if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_getNodeName') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_getNodeName
end
go
 
create procedure absp_getNodeName @dbName as varchar(120), @FolderKey INT, @DBRefKey INT, @AportKey INT,
				@PportKey INT,@RportKey INT, @ProgramKey INT, @CaseKey INT, @taskKey INT, @nodeType INT, 
				@nodeName as varchar(120) out, @rdbInfoKey INT=0, @downloadKey INT=0 
				
as 
declare @qry as nvarchar(max)


begin
	
	set @nodeName = ''
	
	if not exists (select 1 from commondb..cfldrinfo where DB_NAME = ltrim(rtrim(@dbName)))
	begin
		if @nodeType = 102 or @nodeType = 103
		begin
			select @dbName = SDB.name from sys.databases SDB  inner join sys.master_files SMF on SDB.database_id = SMF.database_id  where SMF.file_id = 1 and SDB.state_desc = 'online' and SDB.database_id=@DBRefKey;
			
			set @qry ='use ['+ltrim(rtrim(@dbName))+'] select @nodeName = case '+ cast(@nodeType as varchar(10))+ ' ' +
			'when 102 then (select ltrim(rtrim(longname)) from RdbInfo where rdbInfoKey = ' + cast(@rdbInfoKey as varchar(10))+') ' +
			'when 103 then (select ltrim(rtrim(longname)) from RdbInfo where rdbInfoKey = ' + cast(@rdbInfoKey as varchar(10))+') ' +   
			'else ''''' + 
			'end '
  EXEC sp_executesql @qry,N'@nodeName varchar(50) output',@nodeName output
        end
	    else
			set @nodeName = ''	
	end
	else
	begin
		select @dbName = DB_NAME from commondb..CFldrInfo where Cf_Ref_Key = @DBRefKey;

		set @qry ='use ['+ltrim(rtrim(@dbName))+'] select @nodeName = case '+ cast(@nodeType as varchar(10))+ ' ' +
			'when 0 then (select  ltrim(rtrim(longname)) from fldrinfo where  folder_key = '+ cast(@FolderKey as varchar(10))+' and curr_node=''N'') ' + 
			'when 12 then (select  ltrim(rtrim(longname)) from cfldrInfo where folder_key = '+cast(@FolderKey as varchar(10)) +' and cf_ref_key = '+ cast(@DBRefKey as varchar(10))+') ' +
			'when 1 then (select  ltrim(rtrim(longname)) from AprtInfo where aport_key = '+ cast(@AportKey as varchar(10)) +') ' +
			'when 2 then (select  ltrim(rtrim(longname)) from PprtInfo where pport_key = '+ cast(@PportKey as varchar(10))+') ' + 
			'when 3 then (select  ltrim(rtrim(longname)) from RprtInfo where rport_key = '+ cast(@RportKey as varchar(10))+') ' + 
			'when 7 then (select ltrim(rtrim(longname)) from ProgInfo where  prog_key = '+ cast(@ProgramKey as varchar(10))+') ' + 
			'when 10 then (select ltrim(rtrim(longname)) from CaseInfo where case_key = '+ cast(@CaseKey as varchar(10))+') ' + 
			'when 23 then (select ltrim(rtrim(longname)) from RprtInfo where rport_key = '+ cast(@RportKey as varchar(10))+') ' + 
			'when 27 then (select ltrim(rtrim(longname)) from ProgInfo where prog_key = '+ cast(@ProgramKey as varchar(10))+') ' + 
			'when 30 then (select ltrim(rtrim(longname)) from CaseInfo where case_key = '+ cast(@CaseKey as varchar(10))+') ' +   
			'else ''''' + 
			' end '
			EXEC sp_executesql @qry,N'@nodeName varchar(400) output',@nodeName output
    end
--print @qry
--Select @qry
end