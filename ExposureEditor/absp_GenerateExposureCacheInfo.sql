if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GenerateExposureCacheInfo') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GenerateExposureCacheInfo
end
 go

create procedure absp_GenerateExposureCacheInfo @exposureKey int
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:      	The procedure generates exposure filter information for the given exposureKey.
		
Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/
begin try
	set nocount on
	declare @tableName varchar(130);
	declare @cacheTypeDefID int;
	declare @lookUpTableName varchar(100);
	declare @lookupTblWithSchema varchar(100);
	declare @lookupFieldName varchar(100);
	declare @fieldName varchar(100);
	declare @lookupDisplayName varchar(100);
	declare @userCode varchar(50);
	declare @sql varchar(max);
	declare @nodeKey int;
	declare @nodeType int;
	declare @engineCallId int;
	declare @rqeVersion varchar(1000)
		
	create table #Lookup (LookupId varchar(30), LookupValue varchar(75) COLLATE SQL_Latin1_General_CP1_CI_AS, UserCode varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS);
	create table #LookupVal (CacheTypeDefID int,LookupId varchar(30));
	create table #LookupKeys (LookupKey int);
	create table #CurrCode (CurrencyCode char(3) COLLATE SQL_Latin1_General_CP1_CI_AS);

	declare  reportCurs cursor for select A.TableName,A.FieldName, A.CacheTypeDefID, B.LookupTableName,B.LookupFieldName,B.LookupDisplayColName,B.LookupUserCodeColName
					from DictCol A	inner join CacheTypeDef B
					on A.CacheTypeDefID=B.CacheTypeDefID
					where A.CacheTypeDefID > 0 and A.TableName in (select TableName from DictTbl where TableType='Exposure')
	open reportCurs
	fetch reportCurs into @tableName, @fieldName,@cacheTypeDefID,@lookupTableName,@lookupFieldName,@lookupDisplayName,@UserCode
	while @@fetch_status=0
	begin

		if @cacheTypeDefID=1
		begin
			set @sql = 'insert into #Lookup (UserCode,LookupValue,LookupId)' +
				   'select distinct  A.' + @fieldName + ',B.' + @lookupDisplayName+ '+ '' - ''+ ' + ' Country ' +',B.' + @UserCode   +' from ' + @tableName + ' A inner join ' +  @lookUpTableName + ' B
							on A.' + @fieldName + ' =B.Country_ID'
							 set @sql=@sql + ' and ExposureKey = ' + cast(@exposureKey as varchar(30));
			
		end
		else if @cacheTypeDefID =3
		begin
			
			set @sql = 'insert into #CurrCode select distinct  A.' + @fieldName + ' from ' + @tableName + ' A where ExposureKey = ' + cast(@exposureKey as varchar(30)); 
			exec absp_MessageEx @sql;
			exec (@sql);
			set @sql = 'insert into #Lookup (LookupId , LookupValue,UserCode)' +
					'select distinct  A.' + @LookupFieldName + ',A.' + @lookupDisplayName +',A.' + @UserCode + ' from '   + @lookUpTableName + ' A inner join #CurrCode  B
					on A.' + @UserCode + ' COLLATE DATABASE_DEFAULT = B.CurrencyCode COLLATE DATABASE_DEFAULT ';
		end

		else
		begin
			set @lookupTblWithSchema='';
			--Fixed 0011135: Migration of Lookup IDs does not work if you migrate from RQE 13 or RQE 14
			--Check if table exists in schema
			exec absp_Util_GetDBVersionCol @rqeversion out,'WCEVersion'
			
			if (left(@rqeVersion,3)='14.')
			begin 
				if exists(select 1 from systemdb.sys.Tables where  object_id = object_id('systemdb.RQE1500.' +@lookUpTableName))
					set @lookupTblWithSchema='systemdb.RQE1500.'+@lookUpTableName
				else if exists(select 1 from systemdb.sys.Tables where  object_id = object_id('systemdb.RQE1500.' +dbo.trim(@lookUpTableName) +'_S'))
					set @lookupTblWithSchema='systemdb.RQE1500.'+@lookUpTableName+'_S'
			end
			if @lookupTblWithSchema = '' set @lookupTblWithSchema='dbo.'+@lookUpTableName
				
			-- For big tables, get the distinct list of lookup keys from the main table then join the temp table with the lookup
			-- table for better performance.
			if (@tableName = 'Structure' or @tableName = 'SiteCondition' or @tableName = 'StructureCoverage' or @tableName = 'PolicyCondition' )
			begin
				set @sql = 'insert into #LookupKeys select distinct  A.' + @fieldName + ' from ' + @tableName + ' A where ExposureKey = ' + cast(@exposureKey as varchar(30)); 
				exec absp_MessageEx @sql;
				exec (@sql);
				
				

				set @sql = 'insert into #Lookup (LookupId , LookupValue,UserCode)' +
						'select distinct  A.' + @LookupFieldName + ',A.' + @lookupDisplayName +',A.' + @UserCode + ' from '  + @lookupTblWithSchema + ' A inner join #LookupKeys  B
						on A.' + @LookupFieldName + ' = B.LookupKey';
				
			end
			else
			begin
				set @sql = 'insert into #Lookup (LookupId , LookupValue,UserCode)' +
						'select distinct  A.' + @fieldName + ',B.' + @lookupDisplayName +',B.' + @UserCode + ' from ' + @tableName + ' A inner join '  + @lookupTblWithSchema + ' B
						on A.' + @fieldName + ' =B.' + @LookupFieldName
						 set @sql=@sql + ' and ExposureKey = ' + cast(@exposureKey as varchar(30));
			end		 
		end
		
		exec absp_MessageEx @sql;
		exec (@sql);
			
		delete from #Lookup from #Lookup L1 inner join #LookupVal L2 on L1.LookupID=L2.LookupId and  L2.CacheTypeDefID =@cacheTypeDefID ;

		insert into ExposureCacheInfo (CacheTypeDefID,LookupID,LookupUserCode,Description,ExposureKey)
			select @cacheTypeDefID, LookupId,UserCode, LookupValue,@exposureKey from #Lookup 

		insert into #LookupVal select @cacheTypeDefID,LookupId from #lookup;

		-- Cleanup
		truncate table #Lookup;
		truncate table #LookupKeys;
		truncate table #CurrCode;
		
		fetch reportCurs into @tableName, @fieldName,@cacheTypeDefID,@lookupTableName,@lookupFieldName,@lookupDisplayName,@UserCode
	end
	
	close reportCurs
	deallocate reportCurs	
end try

begin catch
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
end catch