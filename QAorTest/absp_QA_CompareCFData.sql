if exists(SELECT * from SYSOBJECTS where ID = object_id(N'absp_QA_CompareCFData') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_QA_CompareCFData
end
go

create procedure absp_QA_CompareCFData @dbSplitDataPath varchar (8000), @dataUnloadPath varchar (8000)
as
begin
	declare @currencyName varchar(120)
	declare @currencyKey int
	declare @cPath varchar(8000)
	declare @sql varchar(8000)

    if @dbSplitDataPath = @dataUnloadPath
    begin
    	exec absp_MessageEx  'Unload paths must be different.'
    	return
    end
    
	declare c1 cursor for select FOLDER_KEY,LONGNAME from eqe..FLDRINFO where CURR_NODE='Y'
	open c1
	fetch c1 into @currencyKey, @currencyName
	while @@fetch_status=0
	begin
		if exists (select 1 from sys.databases where NAME=@currencyName)
		begin
		
		--Unload tables from currency folder--
		set @cPath = @dbSplitDataPath + '\' + dbo.trim(@currencyName)
		exec absp_Util_CreateFolder @cPath
		set @sql= 'exec [' + @currencyName + ']..absp_UnloadAllTables ''' + @cPath+''''
        exec absp_MessageEx @sql
        exec (@sql)
        
        --Unload data for a currency folder from eqeDB--
        set @cPath = @dataUnloadPath + '\' + dbo.trim(@currencyName)
        exec absp_Util_CreateFolder @cPath
		set @sql= 'exec eqe..absp_QA_GetCFTableData ' + str(@currencyKey) +  ',''' + @cPath+''''
		exec absp_MessageEx @sql
        exec (@sql)
   		end
   		fetch c1 into @currencyKey, @currencyName
	end
	close c1
	deallocate c1
end

