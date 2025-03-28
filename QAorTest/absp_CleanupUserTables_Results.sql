if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_CleanupUserTables_Results') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CleanupUserTables_Results
end
go
create procedure absp_CleanupUserTables_Results 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:	    This procedure will truncate all user tables in the results database so that the database 
                is eqivalent to a fresh results database. There are rows in some tables which will be excluded 
                since they exist in a fresh IR DB.	       

Returns:        It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END
*/

as
begin

	set nocount on
	
	/* SDG__00023329 - New Procedure for QA to cleanup all user tables*/
	--The procedure needs to be executed from IR DB--
	
    -- standard declares
	declare @me  varchar(100)	-- Procedure Name
	declare @msg varchar(1000)		
	declare @sql  varchar(max)
	declare @tableName varchar(120)
	declare @tempTbl varchar(120)
    	declare @query varchar(1000)
    	declare @hasidentity int
	declare @reseedVal int
	declare @cmpMethod char(2)
	declare @keyName char(120)
	declare @blobDB char(1)

	-- initialize standard items
	set @me = 'absp_CleanupUserTables_Results: ' 	-- set to my name Procedure Name
	set @msg = 'Starting ' + @me;
		
	execute absp_messageEx  @msg 
    
    --Rows exist in certain tables in a Fresh database. These rows will be excluded--
    	CREATE TABLE #TMP_RESULTS (TABLENAME VARCHAR(120) COLLATE SQL_Latin1_General_CP1_CI_AS, QUERY VARCHAR(1000) COLLATE SQL_Latin1_General_CP1_CI_AS,RESEEDVAL int)
	insert into #TMP_RESULTS values('FLDRMAP','delete from FLDRMAP where  FOLDER_KEY > 0 or CHILD_KEY > 1',1)
	insert into #TMP_RESULTS values('RBROKER','delete from RBROKER where BROKER_KEY > 1',1)
	insert into #TMP_RESULTS values('RGROUP','delete from RGROUP where RGROUP_KEY > 1',1)
	insert into #TMP_RESULTS values('EXCHRATE','delete from EXCHRATE',0)
	insert into #TMP_RESULTS values('CURRINFO','delete from CURRINFO',0)

	--Drop all constrainst and add them later--
	declare curs cursor for select T1.TABLENAME from DICTCNST T1, DICTTBL T2 
			where T1.TABLENAME=T2.TABLENAME and CF_DB_IR in ('Y','L')
	open curs 
	fetch curs into @tableNAme
	while @@FETCH_STATUS =0
	begin
		exec absp_Util_DropTableConstraint  @tableName
		fetch curs into @tableNAme
	end
	close curs
	deallocate curs

    	--Truncate tables--
    	declare curs1 cursor fast_forward for
	        select TABLENAME from DICTTBL 
	          where DATA_TYPE = 'U' 
	          and TABLENAME not in ('RQEVersion') 
	          and TABLETYPE <>'LOOKUP' 
	          and CF_DB_IR in ('Y','L')
	          order by TABLENAME
	open curs1
	fetch curs1 into @tableName
	while @@fetch_status=0
	begin
		if(not exists(select 1 from #TMP_RESULTS where TABLENAME=@tableName))
		begin
			if( exists(select 1 from SYS.TABLES where NAME=@tableName))
			begin
				set @cmpMethod=''
				select  top 1  @cmpMethod=CMP_METHOD,@keyName = KEYNAME, @blobDB = BLOB_DB from DELCTRL where tablename=@tableName;
				if @cmpMethod='NA' or @cmpMethod='' or @blobDB<>'R'
				begin
					set @sql = 'truncate table ' + @tableName
					execute absp_messageEx  @sql 
	    			execute (@sql)
				end
			   	else
			   	begin
			   		--Table has blob data, negate the key field--
					set @sql = 'update ' + @tableName + ' set ' + @keyName + ' = -' + @keyName;	   		
					execute absp_messageEx  @sql 
	    			execute (@sql)
										
			   	end
				--Drop temporary tables--
    				declare cursTmp cursor fast_forward for select  NAME from SYS.TABLES where NAME  like rtrim(@tableName)+'[_]%'
				open cursTmp
				fetch cursTmp into @tempTbl
				while @@fetch_status=0
				begin
					set @sql= 'drop table ' + @tempTbl 
					execute absp_messageEx @sql
					exec (@sql)
						
					fetch cursTmp into @tempTbl
				end
				close cursTmp
				deallocate  cursTmp
				---
			end
	    end
		fetch curs1 into @tableName

	end 
	close curs1
	deallocate curs1

    --Delete rows from tables excluding certain rows which exist in a fresh DB--
    declare curs2 cursor fast_forward for select TABLENAME,QUERY,RESEEDVAL from #TMP_RESULTS
	open curs2
	fetch curs2 into @tableName, @query, @reseedVal
	while @@fetch_status=0
	begin  
		if @query<>'' 
		begin
	    	--Delete rows from main table--
			execute absp_messageEx  @query 
			execute(@query)
		
			-- Check if there is an identity column
			select @hasidentity= isnull(objectproperty ( object_id(''+@tableName+'') , 'tablehasidentity' ) ,-1)
			if @hasidentity = 1 
			begin
			   --Reset seed value--
        	   DBCC CHECKIDENT (@tableName, RESEED, @reseedVal)
			end		
		end
		fetch curs2 into @tableName, @query, @reseedVal
	end
	close curs2
	deallocate curs2
	

	--Add all constraint--
	declare curs3 cursor for select T1.TABLENAME from DICTCNST T1, DICTTBL T2 
		where T1.TABLENAME=T2.TABLENAME and CF_DB_IR in ('Y','L')
	open curs3 
	fetch curs3 into @tableName
	while @@FETCH_STATUS =0
	begin
		exec absp_Util_CreateTableConstraint @tableName
		fetch curs3 into @tableName
	end
	close curs3
	deallocate curs3
	
	set @msg = @me + 'complete' 
	execute absp_messageEx  @msg 
	
end
