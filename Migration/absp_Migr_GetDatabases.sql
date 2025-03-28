if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_GetDatabases') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_GetDatabases;
end
go

create procedure absp_Migr_GetDatabases
	@externalDatabaseServerName varchar(130)='',
	@externalDatabaseInstanceName varchar(200)='',
	@userName varchar(100)='',
	@password varchar(100)='',
	@isLocalServer int=0
as
/*
##BD_begin
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================

Purpose:	The procedure connects to the external server and then gets the list of all databases of version 3.16.

Returns:	 A list of NodeKey, NodeType (always 12) and the database name.


====================================================================================================
</pre>
</font>
##PD  @externalDatabaseServerName ^^ The remote serverName where the databases exists.
##PD  @externalDatabaseInstanceName ^^ The remote instanceName
##PD  @userName ^^ The userName of the remote server
##PD  @password ^^ The password  of the remote server

##BD_END
*/
begin
	set nocount on

		declare @sql nvarchar(max)
		declare @csql varchar(1000)
		declare @sSql varchar(max)
		declare @dbName varchar(200)
		declare @severCreated int
		declare @formattedDBName varchar(200)
		declare @linkedServerName varchar(20)
		declare @serverNameStr varchar(20)
		
		set @linkedServerName=''
		set @serverNameStr=''
		
		begin try
			if @isLocalServer<>1
			begin
				set @linkedServerName='LknSvrForDB'
				set @serverNameStr=@linkedServerName+'.'
				
				--Create a link server to the external database.
				exec @severCreated=absp_CreateLinkedServer @linkedServerName,@externalDatabaseServerName, @externalDatabaseInstanceName,'master',@userName,@password

				if @severCreated=1 return --Error creating linked server
				exec absp_MessageEx  'Created Linked server'
			end

			--Create temporary table--
			create table #TMP (NodeKey int, NodeType int, DBName varchar(200))

			--Get the list of all databases excluding system db,IR db,systemdb and commondb
			set @csql='select name from ' +  @serverNameStr + 'master.sys.databases where owner_sid <> 1 and RIGHT(rtrim(Name),3) != ''_IR'' and name<>''systemdb'' and name<>''commondb'''

			execute('declare c1 cursor global for '+@csql)
			open c1
			fetch c1 into @dbName
			while @@fetch_status=0
			begin
				begin try
					--Add square brackets--
					execute absp_getDBName @formattedDBName out, @dbName

					--get the 3.16 databases only--
					if @isLocalServer=1
					begin
						set @sql = 'if exists(select 1 from ' +dbo.trim(@formattedDBName)+ '.sys.tables where name =''version'') '
						set @sql = @sql + 'insert into #TMP (DBName)   select ''' + dbo.trim(@dbName) + ''' from ' +dbo.trim(@formattedDBName)+ '..version where WCEVERSION like ''3.16%'''
					end
					else
					begin
						set @sql = 'if exists(select 1 from ' +dbo.trim(@formattedDBName)+ '.sys.tables where name =''version'') '
						set @sql = @sql + ' select ''' + dbo.trim(@dbName) + ''' from ' +dbo.trim(@formattedDBName)+ '..version where WCEVERSION like ''3.16%'''
						set @sql=replace (@sql,'''','''''')
						set @sSql = 'INSERT INTO #TMP (DBName) SELECT * FROM OPENQUERY(LknSvrForDB, ''@sSql'')';
						set @sql = REPLACE(@sSql, '@sSql', @sql);
					end				

					exec absp_MessageEx @sql
					exec(@sql)

					--Add nodeKey and NodeType--
					set @sSql='select * from ' +dbo.trim(@formattedDBName)+ '..CFLDRINFO where DB_NAME= ''''' + @dbName + ''''''
					if @isLocalServer=1
						set @sql='UPDATE #TMP set NodeKey=T2.Cf_Ref_Key ,NodeType=12 from #TMP t1 join ( ' + @ssql + ') T2 on T1.DBName=T2.DB_Name'
					else
						set @sql='UPDATE #TMP set NodeKey=T2.Cf_Ref_Key ,NodeType=12 from #TMP t1 join ( SELECT * FROM openquery(LknSvrForDB, ''' + @ssql + ''')) T2 on T1.DBName=T2.DB_Name'

					exec absp_MessageEx @sql
					exec(@sql)

				end try
				begin catch

				end catch

				fetch c1 into @dbName
			end
			close c1
			deallocate c1

		--Drop linked server
		if exists(select 1 from master.sys.sysservers where srvName=@linkedServerName) exec sp_dropserver @linkedServerName, 'droplogins'

		select distinct NodeKey, NodeType, DBName from #TMP order by DBName;

	end try

	begin catch
		select -1 as NodeKey, -1 as NodeType, '' as DBName
		select ERROR_MESSAGE() as ErrorMessage
		return
	end catch

	select '' as ErrorMessage;
end
