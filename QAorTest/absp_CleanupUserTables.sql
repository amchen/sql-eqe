if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_CleanupUserTables') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CleanupUserTables
end
go
create procedure absp_CleanupUserTables 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:	    This procedure will truncate all user tables so that the database is eqivalent to a
                fresh database. There are rows in some tables which will be excluded since they exist 
                in a fresh database.	       

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
	
    -- standard declares
	declare @me  varchar(100)	-- Procedure Name
	declare @msg varchar(1000)		
	declare @sql  varchar(max)
	declare @tableName varchar(120)
    	declare @query varchar(1000)
    	declare @fieldNames varchar(max)
    	declare @hasidentity int
	declare @isTmpTableExists int
	declare @reseedVal int

	-- initialize standard items
	set @me = 'absp_CleanupUserTables: ' 	-- set to my name Procedure Name
	set @msg = 'Starting ' + @me;
		
	execute absp_messageEx  @msg 
    
    	--Rows exist in certain tables in a Fresh database. These rows will be excluded--
    	CREATE TABLE #TMP (TABLENAME VARCHAR(120) COLLATE SQL_Latin1_General_CP1_CI_AS, QUERY VARCHAR(1000) COLLATE SQL_Latin1_General_CP1_CI_AS,RESEEDVAL int)
    	INSERT INTO #TMP VALUES('FLDRINFO','delete from FLDRINFO where FOLDER_KEY >1',1)
	INSERT INTO #TMP VALUES('FLDRMAP','delete from FLDRMAP where FOLDER_KEY > 0 or CHILD_KEY > 1',0)
	INSERT INTO #TMP VALUES('EXCHRATE','delete from EXCHRATE where CURRSK_KEY	> 1',0)
	INSERT INTO #TMP VALUES('CURRINFO','delete from CURRINFO where CURRSK_KEY > 1',1)
	INSERT INTO #TMP VALUES('ANALCFIG','delete from ANALCFIG  where anlcfg_key>1 and ANLCFG_KEY<-8',1)
	INSERT INTO #TMP VALUES('CROLINFO','delete from CROLINFO  WHERE CALCR_ID>1',0)
	INSERT INTO #TMP VALUES('LKUPCLSS','delete from LKUPCLSS  WHERE LKUPCLSSID>5',0)
	INSERT INTO #TMP VALUES('RBROKER','delete from RBROKER WHERE BROKER_KEY>1',1)
	INSERT INTO #TMP VALUES('RGROUP','delete from RGROUP WHERE RGROUP_KEY>1 ',1);
	INSERT INTO #TMP VALUES('RPRGSTAT','delete from RPRGSTAT   WHERE PGSTAT_KEY>4',4)
	
	--Do not delete these tables--
	INSERT INTO #TMP VALUES('TMPL','',0)
	INSERT INTO #TMP VALUES('TMPLCOL','',0)
	INSERT INTO #TMP VALUES('USRDFLT','',0)
	INSERT INTO #TMP VALUES('NEPEXCED','',0)
	INSERT INTO #TMP VALUES('ROWCNT','',0)
	
	--Drop all constrainst and add them later--
	declare c1 cursor for select T1.TABLENAME from DICTCNST T1, DICTTBL T2 
		where T1.TABLENAME=T2.TABLENAME and CF_DB in ('Y','L')
	open c1 
	fetch c1 into @tableNAme
	while @@FETCH_STATUS =0
	begin
		exec absp_Util_DropTableConstraint  @tableName
		fetch c1 into @tableNAme
	end
	close c1
	deallocate c1

    --Truncate tables--
    declare curs1 cursor fast_forward for
	        select TABLENAME from DICTTBL 
	          where DATA_TYPE = 'U' 
	          and TABLENAME not in ('RQEVersion') 
	          and TABLETYPE <>'LOOKUP' 
	          and CF_DB in ('Y','L')
	          order by TABLENAME
	open curs1
	fetch curs1 into @tableName
	while @@fetch_status=0
	begin
		if(not exists(select 1 from #TMP where TABLENAME=@tableName))
		begin
			if( exists(select 1 from SYS.TABLES where NAME=@tableName))
			begin
    			set @sql = 'truncate table ' + @tableName
    			execute absp_messageEx  @sql 
	    		execute (@sql)
			end
	    end
		fetch curs1 into @tableName

	end 
	close curs1
	deallocate curs1

    --Delete rows from tables excluding certain rows which exist in a fresh DB--
    --Truncate statement resets the seed value for Identity Columns whereas delete does not --
    declare curs2 cursor fast_forward for select TABLENAME, QUERY, RESEEDVAL from #TMP
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
	declare c1 cursor for select T1.TABLENAME from DICTCNST T1, DICTTBL T2 
		where T1.TABLENAME=T2.TABLENAME and CF_DB in ('Y','L')
	open c1 
	fetch c1 into @tableName
	while @@FETCH_STATUS =0
	begin
		exec absp_Util_CreateTableConstraint @tableName
		fetch c1 into @tableName
	end
	
	close c1
	deallocate c1
	
	set @msg = @me + 'complete'
	execute absp_messageEx @msg
	
end
