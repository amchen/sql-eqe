if exists (select 1 from SYSOBJECTS where ID = object_id(N'absp_ValidateLookupEntries') and objectproperty(ID,N'IsProcedure') = 1)
begin
    drop procedure absp_ValidateLookupEntries
end
go

create  procedure  absp_ValidateLookupEntries   
/*
##BD_BEGIN
<font size="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version: MSSQL
Purpose:    This procedure validats the lookup table entries and checks if they are in sync.
Returns:    Nothing.
====================================================================================================
</pre>
</font>
##BD_END

*/
as

begin
	set nocount on
	declare @i int
	declare @sql varchar(max)
	declare @tableName varchar(120)
	declare @refTableName varchar(120)
	declare @columnName varchar(120)
	declare @refColName varchar(120)
	declare @fName varchar(120)
	declare @debug int
	
	set @debug = 1 
	
	--Create temporay table to hold the missing entry messages--
	create table #TMP_LOOKUPTBL_MSG(  TABLENAME varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS,REFTABLENAME varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS, COUNTRY_ID char(3) COLLATE SQL_Latin1_General_CP1_CI_AS,ID int,STR_TYP_COL varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS, STR_TYP int)
	
	--Create temporary table to hold the lookup table and column names to validate--
	create table #TMP_LOOKUP (TABLENAME varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS,COLUMNNAME varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS, REFTABLENAME varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS , REFCOLNAME varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS)
	insert into #TMP_LOOKUP values('ESDL','STR_EQ_ID','ESI','EQ_STR_TYP')
	insert into #TMP_LOOKUP values('WSDL','STR_WS_ID','WSI','WS_STR_TYP')
	insert into #TMP_LOOKUP values('FSDL','STR_FD_ID','FSI','FD_STR_TYP')
	
	--Check each lookup table--
	declare c1 cursor for select TABLENAME,COLUMNNAME,REFTABLENAME,REFCOLNAME from #TMP_LOOKUP 
	open c1
	
	fetch c1 into  @tableName,@columnName,@refTableName,@refColName 
	while @@FETCH_STATUS =0
	begin
	    --Loop for each STR_TYPE (1,2,3,4,5)--
	    set @i=1
	    if OBJECT_ID('TMP_MISSING_ROWS','u') IS NOT NULL drop table TMP_MISSING_ROWS
	    
	    create table TMP_MISSING_ROWS(COUNTRY_ID char(3),STR_TYP int)
	
	    while @i<6
	    begin
		
		set @fName = 'STR_TYPE_' + dbo.trim(cast(@i as varchar))
		
		--Get the missing country and struct type--
		set @sql = 'insert into TMP_MISSING_ROWS (COUNTRY_ID,STR_TYP)'+
				' select country_id,' + @fName + ' from ' + @tablename + ' where ' + @fName + ' > 0 '+ 
				' except ' +
				' select country_id, ' + @refColName + ' from ' + @refTableName 
		if @debug=1
			exec absp_MessageEx @sql 
		exec (@sql)		
		
		--Insert in the message table the missing entries with other info--
		set @sql = 'insert into #TMP_LOOKUPTBL_MSG (TABLENAME,REFTABLENAME,COUNTRY_ID,STR_TYP_COL,STR_TYP,ID)  
					select DISTINCT ''' + @tableName + ''','''+ @refTableName + ''',T1.COUNTRY_ID,''' + @fName + ''',STR_TYP, ' + @columnName + 
					' from TMP_MISSING_ROWS T1 ,' + @tableName + ' T2 
					where T1.COUNTRY_ID = T2.COUNTRY_ID and STR_TYP = T2.' + @fName        
		if @debug=1
			exec absp_MessageEx @sql 
			
		exec (@sql)
		
				
		set @i= @i + 1
		
	      end
	      drop table TMP_MISSING_ROWS

	      fetch c1 into  @tableName,@columnName,@refTableName,@refColName 
	end 
	close c1
	deallocate c1
	select distinct TABLENAME + ' ( Id = ' + dbo.trim(CAST(ID as varchar))+ ' and ' +STR_TYP_COL + ' = ' + dbo.trim(cast(STR_TYP as varchar)) + ' ) is missing from Table ' + REFTABLENAME + ' for Country ID = ' + COUNTRY_ID  as MSG from  #TMP_LOOKUPTBL_MSG
 
end

 
 
 
