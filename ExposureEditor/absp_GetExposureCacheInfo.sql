if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetExposureCacheInfo') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetExposureCacheInfo
end
 go

create procedure absp_GetExposureCacheInfo  @nodeKey int,@nodeType int
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:      	This procedure will retrieve the exposure filter information for any given node. 
		The exposure filter information can be retrieved for the following node levels:
		a.	Accumulation Portfolio
		b.	Primary Portfolio
		c.	Reinsurance Portfolio
		d.	Program Node
.
Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/

begin try
	set nocount on
	declare @exposureKeyList varchar(max);
	declare @sql varchar(max);
	declare  @cDefId int;
	declare @LookupTbl varchar(130);
	declare @LookupFieldName varchar(130);
	declare @lookupUserCode varchar(100);
	declare @lookupDesc varchar(100);
	declare @ExposureCacheInfoKey int;
	declare @ExpCacheInfoKeyInList varchar(max);
	
	--Create temporary tables--
	create table #TmpExposureCache (ExposureCacheInfoKey int,ExposureKey int, CacheTypeDefId int,  CacheTypeName varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS, LookupId int, 
			LookupUserCode varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS,Description varchar(75) COLLATE SQL_Latin1_General_CP1_CI_AS, DefaultRow varchar(1)COLLATE SQL_Latin1_General_CP1_CI_AS);
	create table #ExposureCache (ExposureKey int,  CacheTypeName varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS, LookupId int, 
			LookupUserCode varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS,
			Description varchar(75) COLLATE SQL_Latin1_General_CP1_CI_AS,DefaultRow varchar(1)COLLATE SQL_Latin1_General_CP1_CI_AS,Country_ID varchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS);
	create table #Country (Country_ID varchar(3) COLLATE SQL_Latin1_General_CP1_CI_AS);
	------------------------------
	
	exec absp_Util_GetExposureKeyList @exposureKeyList out, @nodeKey,@nodeType

	if len(@exposureKeyList)>0
	begin
		--Handle the entries which are  country specific--
 		set @sql='insert into #TmpExposureCache
 			select distinct ExposureCacheInfoKey,A.ExposureKey,B.CacheTypeDefID, B.CacheTypeName, A.LookupID, A.LookupUserCode, A.Description,''N'' as DefaultRow 
			from ExposureCacheInfo  A inner join CacheTypeDef B 
		on A.CacheTypeDefID=B.CacheTypeDefID
		where ExposureKey ' + @exposureKeyList + ' and B.IsCountrySpecific=''Y'''
		exec absp_MessageEx @sql 
		exec (@sql)
		
		--Get the country list--
		set @sql = 'insert into #Country 
			select distinct LookupUserCode from ExposureCacheInfo where ExposureKey ' + @exposureKeyList + ' and CacheTypeDefID=1'
		exec absp_MessageEx @sql 
		exec (@sql)
		
		--Get countryIds for the ExposureCache entry--
		--For each CacheTypeDeID, get the ExposureCacheInfoKeys and join with lookup tables for specific countries		
		declare curs cursor for select distinct  CacheTypeDefID from  #TmpExposureCache T
		open curs
		fetch curs into @cDefId
		while @@FETCH_STATUS =0
		begin
			set @sql='select  ExposureCacheInfoKey from #TmpExposureCache where CacheTypeDefID=' + cast(@cDefId as varchar(30))
			exec absp_Util_GenInList @ExpCacheInfoKeyInList out,@sql
			
			--Get Lookup table info for the cacheTypedefID		
			select @LookupTbl=LookupTableName,@LookupFieldName=LookupFieldName,@lookupUserCode=LookupUserCodeColName,@lookupDesc=LookupDisplayColName from CacheTypeDef 
					where CacheTypeDefID=@cDefId
		
			set @sql='insert into #ExposureCache
				select A.ExposureKey,A.CacheTypeName, A.LookupID,  A.LookupUserCode, A.Description,''N'' as DefaultRow,B.Country_ID
					from #TmpExposureCache A inner join ' + @LookupTbl + ' B on A.LookupId=B.' + @LookupFieldName  + ' and A.LookupUserCode=B.' + @lookupUserCode + 
					' and A.Description=B.' + @lookupDesc +
					' inner join #Country Z on B.Country_ID=Z.Country_ID' +
					' where ExposureCacheInfoKey  ' + cast(@ExpCacheInfoKeyInList as varchar(max))				
			
			exec absp_MessageEx @sql 
			exec (@sql)	
			fetch curs into @cDefId
		end
		close curs
		deallocate curs	

			
		------------------------------------------------
		--Now get the entries which are not country specific--
 		set @sql='insert into #ExposureCache
 			select distinct A.ExposureKey,B.CacheTypeName, A.LookupID, A.LookupUserCode, A.Description,''N'' as DefaultRow , ''''
			from ExposureCacheInfo  A inner join CacheTypeDef B 
		on A.CacheTypeDefID=B.CacheTypeDefID
		where ExposureKey ' + @exposureKeyList + ' and B.IsCountrySpecific=''N'''
		--exec absp_MessageEx @sql 
		exec (@sql)
		
		select distinct ExposureKey as ExposureKey,CacheTypeName as CacheTypeName,LookupId as LookupId, 
			LookupUserCode as LookupUserCode,
			Description as Description,DefaultRow as DefaultRow,Country_ID as Country_ID
		 from #ExposureCache order by Description;
	end
	else
		select distinct ExposureKey as ExposureKey,'' as CacheTypeName, LookupID as LookupId, LookupUserCode as LookupUserCode, 
			Description as Description,'' as DefaultRow, '' as Country_ID from ExposureCacheInfo where 1=0 order by Description;
	
end try

begin catch
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
end catch