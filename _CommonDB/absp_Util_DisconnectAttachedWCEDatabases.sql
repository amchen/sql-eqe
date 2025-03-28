if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_Util_DisconnectAttachedWCEDatabases') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_DisconnectAttachedWCEDatabases
end
go
 
create procedure absp_Util_DisconnectAttachedWCEDatabases 
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure will remove the entries of databases from CFLDRINFO before performing cleanup tasks
     for the databases that are not cuurently attached.
     It will not physically detach any database.
     
    	    
Returns: Nothing.
====================================================================================================
</pre>
</font>
##BD_END 
*/
as
begin

set nocount on

	declare @cfRefKey int
	declare @dbName varchar(120)
	declare @attrib int
	declare @attribName varchar(25)
	declare @IRDBName varchar(120)
	declare @isSingleUser int
	declare @isOffline int
	declare @isIRDBSingleUser int
	declare @isIRDBOffline int

	--Get the list of databases --
	declare attachedCurrDB cursor fast_forward for select CF_REF_KEY, DB_NAME from CFLDRINFO
	
	open attachedCurrDB
	fetch next from attachedCurrDB into @cfRefKey, @dbName 
	while @@fetch_status = 0
	begin
		
		--Fixed defect 7057
		--If the database is getting copied, do not remove entry from cfldrinfo and others
		-- since the db gets temporarily detached while copying.
		exec absp_InfoTableAttribGetCurrencyCopyInProgress  @attrib out,@cfRefKey
		
		if @attrib=0
		begin
			set @IRDBName = dbo.trim(@dbName) + '_IR'
			--Check if the database is attached--
			if not exists (select  1 from SYS.DATABASES where NAME = @dbName) OR not exists (select  1 from SYS.DATABASES where NAME = @IRDBName)
			begin
				--Detach only if db in not migrating mode--
				exec absp_InfoTableAttribGetCurrencyMigrationProgress  @attrib out,@cfRefKey
				if @attrib=0
				begin
					--Check if it is in Detaching mode--
					exec absp_InfoTableAttribGetCurrencyDetachProgress  @attrib out,@cfRefKey

					if @attrib = 0
					begin
						--Mark the CFLDRINFO ATTRIB value as 'Detaching'--
						set @attribName = 'CF_DETACH_IN_PROGRESS'
						exec absp_InfoTableAttrib_Set 12,@cfRefKey,@attribName,1

						--Remove SEQPLOUT, BatchJob and BatchJobStep entries associated with this database--
						delete from commondb..SEQPLOUT where BatchJobKey in
							(select BatchJobKey from commondb..BatchJob where DBName=@dbName)

						delete from commondb..BatchJobStep where BatchJobKey in
							(select BatchJobKey from commondb..BatchJob where DBName=@dbName)

						delete from commondb..BatchJob where DBName=@dbName

					end

					--Remove the CFLDRINFO entry for this database--
					delete from commondb..CFLDRINFO where DB_NAME=@dbName
				end
			end
			else
			begin
				--Check if single user mode--
				select  @isSingleUser = DATABASEPROPERTY(@dbName, 'IsSingleUser') 
				select  @isIRDBSingleUser = DATABASEPROPERTY(@IRDBName, 'IsSingleUser') 
				select  @isOffline = DATABASEPROPERTY(@dbName, 'IsOffline') 
				select  @isIRDBOffline = DATABASEPROPERTY(@IRDBName, 'IsOffline')
				--exec absp_InfoTableAttribGetOfflineMode  @isOffline out,@cfRefKey
				--exec absp_InfoTableAttribGetOfflineMode  @isIRDBOffline out,@cfRefKey

				if @isOffline = 1 or  @isIRDBOffline = 1
				begin
					exec absp_InfoTableAttribSetOfflineMode  @cfRefKey,1
					exec absp_InfoTableAttribSetCurrencyNodeAvailable  @cfRefKey,0 
				end
				else
				begin
					exec absp_InfoTableAttribSetOfflineMode  @cfRefKey,0
					exec absp_InfoTableAttribSetCurrencyNodeAvailable  @cfRefKey,1
				end

				if @isSingleUser = 1 or  @isIRDBSingleUser = 1
					exec absp_InfoTableAttribSetCurrencySingleUser  @cfRefKey,1 
				else
					exec absp_InfoTableAttribSetCurrencySingleUser  @cfRefKey,0


			end
		end
		
		fetch next from attachedCurrDB into @cfRefKey, @dbName 
	end
	close attachedCurrDB
	deallocate attachedCurrDB
end