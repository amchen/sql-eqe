if exists(SELECT * from SYSOBJECTS where ID = object_id(N'absp_QA_UnloadSystemData') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_QA_UnloadSystemData
end
go

create procedure absp_QA_UnloadSystemData @unloadPath varchar (8000), 
                                          @dbName varchar(50)='systemdb',
										  @userName varchar(100)='', 
										  @password varchar(100)=''
as
begin
	declare @tableName varchar(100)
    declare @outputPath varchar(8000)
    declare @query varchar(max)
    declare @colNames varchar(8000)
    
    --The procedure unloads  systemdb/commondb DB tables from systemdb, commondb or EqeSingle DB
    --depending on the arguments
    
    
    --If we run the procedure from systemdb or commondb we may not provide @dbName--
    --In case we call the procedure from a Eqe singleDB, @dbName is mandatory--
    
    if @dbName='systemdb' or (@dbName='' and DB_NAME()='systemdb')
		declare c1 cursor for select TABLENAME from DICTTBL where SYS_DB in ('L','Y')
	else if @dbName='commondb' or (@dbName='' and DB_NAME()='commondb')
		declare c1 cursor for select TABLENAME from DICTTBL where COM_DB in ('L','Y')
    else
    begin
		exec absp_MessageEx 'Incorrect DBName'
		return
    end

	open c1
	fetch c1 into @tableName
	while @@fetch_status=0
	begin
		if exists (select 1 from sys.tables where NAME=@tableName)
         begin
            set @outputPath = @unloadPath+'\'+@tableName+'.txt'
            
            exec absp_DataDictGetFields @colNames output,@tableName,0
			set @query = 'select * from ' + DB_NAME() + '.dbo.' + @tableName + ' order by ' + @colNames									  
			exec absp_Util_UnloadData 'Q', @query, @outputPath , @userName=@userName,@password=@password
         end
   		fetch c1 into @tableName
	end
	close c1
	deallocate c1
end

