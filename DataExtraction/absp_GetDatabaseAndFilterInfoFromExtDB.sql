if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GetDatabaseAndFilterInfoFromExtDB') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_GetDatabaseAndFilterInfoFromExtDB;
end
go

create procedure  absp_GetDatabaseAndFilterInfoFromExtDB @serverName varchar(100)='', 
							 @instanceName varchar(100)='',
							 @userName varchar(100)='',
							 @password varchar(100)='',
							 @filterQuery varchar(max),
							 @sessionId int,
							 @isLocalServer int=0
as

/*
##BD_begin
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================

Purpose:	This procedure will get the list of all databases in a remote server and then  execute the filter query
		in each database to get the list of filter names. 
		
Returns:	A resultset having DatabaseName and FilterName. 


====================================================================================================
</pre>
</font>
##PD  @exposureKey ^^ The exposureKey
##BD_END
*/
begin
	set nocount on
	
	declare @lknServerName varchar(20);
	declare @severCreated int;
	declare @dbName varchar(200);
	declare @sql varchar(max);
	declare @msg varchar(1000);
	declare @tname varchar(100);
	declare @serverNameStr varchar(20)
					
	set @lknServerName=''
	set @serverNameStr=''
	
	exec absp_ParseQuery @filterQuery out, @filterQuery
	
	
 	
	--Create a link server to the external database 
	begin try
		if @isLocalServer<>1
		begin
			set @lknServerName='LknSvr_' + dbo.trim(cast(@sessionId as varchar(20)))
			set @serverNameStr=@lknServerName + '.'
			exec @severCreated=absp_CreateLinkedServer @lknServerName,@serverName, @instanceName,'master',@userName,@password
			exec absp_MessageEx  'Created Linked server'
		end

		--Create  temporary tables to hold the result
		create table #TMP_DBFilter (DBName varchar(200) , Filter varchar(8000))
		create table #TMP ( Filter varchar(8000))

		--Get the list of all databases
		set @sql='select name from ' + @serverNameStr + 'master.sys.databases'
		execute('declare c1 cursor global for '+@sql)
		open c1
		fetch c1 into @dbName
		while @@fetch_status=0
		begin
			begin try
				--execute query and insert in temp table
				if @isLocalServer<>1
					set @sql = 'INSERT INTO #TMP  SELECT * FROM OPENQUERY(@svrName, ''@filterQuery'')';
				else
					set @sql = 'INSERT INTO #TMP  ' + @filterQuery ;
								set @sql = REPLACE(@sql, '@svrName', @lknServerName);
					set @sql = REPLACE(@sql, '@filterQuery', @filterQuery);
					set @sql = REPLACE(@sql, '@dbName', '[' + @dbName + ']')
				exec absp_MessageEx @sql
				exec(@sql) 

			end try
			begin catch
				set @msg='Unable to execute filter query in ' + @dbName
				exec absp_MessageEx  @msg
			end catch

			insert into #TMP_DBFilter select @dbName, Filter from #TMP
			delete from #TMP
			fetch c1 into @dbName
		end 
		close c1
		deallocate c1

		--Return resultset
		select DBName,Filter from  #TMP_DBFilter order by DBName,Filter


		--Drop linked server
		if exists(select 1 from master.sys.sysservers where srvName=@lknServerName) exec sp_dropserver @lknServerName, 'droplogins'
	end try
	begin catch
		select '' as DBName ,'' as Filter 
		select ERROR_MESSAGE() as ErrorMessage
		return
	end catch
					
	select '' as ErrorMessage
	
end

