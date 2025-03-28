if exists(select 1 from dbo.SYSOBJECTS where ID = object_id(N'dbo.absp_TreeviewExposureDelete') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure dbo.absp_TreeviewExposureDelete;
end
go

create procedure dbo.absp_TreeviewExposureDelete @exposure_Key int, @parentKey int, @parentType int, @targetDbName varchar(120) = ''

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose: This procedure  marks records in ExposureInfo as 'DELETED' for the givenExposureKey and removes the
         map entry from ExposureMap.
Returns: None.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @exposure_Key ^^  The key of the exposure which is to be deleted.
##PD  @parentKey    ^^  The parent key of the exposure which is to be deleted.
##PD  @parentType   ^^  The parent type of the exposure which is to be deleted.
*/

as

begin

	set nocount on;

	declare @sqlQuery nvarchar(max);
	declare @dbName  varchar(130);
	declare @IRDBName  varchar(130);
	declare @cntExpkey int;

	set @sqlQuery = '';
	if @targetDBName = ''
		set @dbName = DB_NAME();
	else
		set @dbName = @targetDBName;

	--Enclose within square brackets--
	execute absp_getDBName @dbName out, @dbName;

	--Delete ExposureCount
	set @sqlQuery =	'delete ' + @dbName +'..ExposureCount where ExposureKey = ' + cast(@exposure_Key as varchar(20));
	execute sp_executesql @sqlQuery;
	--ExposureInfo
	set @sqlQuery =	'update ' + @dbName +'..ExposureInfo set STATUS = ''DELETED''  where ExposureKey = ' + cast(@exposure_Key as varchar(20));
	execute sp_executesql @sqlQuery;
	--ExposureReportInfo
	set @sqlQuery =	'update ' + @dbName +'..ExposureReportInfo set STATUS = ''DELETED''  where ExposureKey = ' + cast(@exposure_Key as varchar(20));
	execute sp_executesql @sqlQuery;

	if RIGHT(rtrim(@dbName),4) != '_IR]'
		exec absp_getDBName  @IRDBName out, @dbName, 1;
	else
		set @IRDBName = @dbName;

	--Delete exposures from  ExposureLookupIDMap--
	set @sqlQuery =	'delete ' + @dbName +'..ExposureLookupIDMap where ExposureKey = ' + cast(@exposure_Key as varchar(20));
	execute sp_executesql @sqlQuery;
	
	--ExposureBrowserData needs to be regenerated--
	--If exposure filter is set for the current ExposureSet, then Regenerate else do not--
	
	--Check if ExposureSetFilter is defined--
	--If the Importstatus is cancelled or failed, so not set bit--
	if exists(select 1 from ExposureInfo where ExposureKey=@exposure_Key and ImportStatus='Completed')
	begin
		if exists( select 1 from ExposureDataFilterInfo A inner join ExposureCategoryDef B
			on A.CategoryID=B.CategoryID and B.Category='ExposureSetFilter' and  NodeKey=@parentKey and NodeType=@parentType )
		begin
			--Check if filter is defined for the current exposure--
			if exists( select 1 from ExposureDataFilterInfo A inner join ExposureCategoryDef B
				on A.CategoryID=B.CategoryID and B.Category='ExposureSetFilter' and  NodeKey=@parentKey and NodeType=@parentType 
				and Value=@exposure_Key)
			begin
				--Filter is  defined for this ExposureSet
				exec absp_InfoTableAttribSetBrowserDataRegenerate @parentType,@parentKey,1 
				-- clean up statistics
				delete from FilteredStatReport where NodeKey=@parentKey and NodeType=@parentType;
			end
		end
		else
		begin
			exec absp_InfoTableAttribSetBrowserDataRegenerate @parentType,@parentKey,1 
			-- clean up statistics
			delete from FilteredStatReport where NodeKey=@parentKey and NodeType=@parentType;
		end	
	end
	
end
