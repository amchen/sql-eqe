if exists ( select 1 from sysobjects where name =  'absp_Util_ResetRtroLayrLineOfBusinessID' and type = 'P' ) 
begin
	drop procedure absp_Util_ResetRtroLayrLineOfBusinessID
end 
GO
create procedure absp_Util_ResetRtroLayrLineOfBusinessID @nodeKey int,@nodeType int
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:		MSSQL

Purpose:		This procedure sets certain LOBs of RtroLineOfBusiness to zero (unspecified) when a primary or reinsurance
				portfolio is deleted underneath an Accumulation Porfolio. Only the  LOBs are referenced by deleted
				Primary or Reinsurance Portfolio will be reset. 
        	    
Returns:		N/A.
====================================================================================================
</pre>
</font>
##BD_END

##PD @nodeKey ^^  The (APort) node key that has its portfolios being deleted underneath it.
##PD @nodeType ^^  The (Aport) node type that has its portfolios being deleted underneath it.


*/


as
begin

	set nocount on;
	declare @expKeyInList	varchar(max);
	declare @lbIdInList	varchar(max);
	declare @lobInList	varchar(max);
	declare @sql		varchar(max);
	declare @me		char	(255);
	declare @rtLayrKey	int
	
	
   	set @me = 'absp_Util_ResetRtroLayrLineOfBusinessID';
        
	-- Get the list of undeleted ExposureKeys under the Aport (AFTER its portfolios were deleted underneath it).
	exec absp_Util_GetExposureKeyList @expKeyInList output, @nodeKey, @nodeType;
	exec absp_Util_Log_HighLevel @expKeyInList, @me;
	
	-- Get all LineOfBusinessID  of undeleted portfolios
	if (len (@expKeyInList) > 0)
	begin
		create table #TMP1 (LineOfBusinessID int)
		set @sql='insert into #TMP1 select distinct ID  from ExposureLookupIDMap where ExposureKey ' + dbo.trim(@expKeyInList) + ' and CacheTypedefID = 10';	
		exec (@sql)
	end
	else
		return
	
	-- Get the  list of LineOfBusinessIDs that are used by the APORT.
	select LineOfBusinessID into #TMP2  from AportRtroLayerMap A inner join RtroLineOfBusiness B on A.RtLayerKey=B.RtlayerKey
			where AportKey = @nodeKey;
	 
	 
	-- Remove all the retro layer entries in RtroLineOfBusiness that contain any LineOfBusinessIDs that are not in the list 
	--and replace these layer entries with a single record of RtLayerKey=existingKey, LineOfBusinessID=0 (unspecified) in RtroLineOfBusiness for each removed RtLayerKey.
	create table #TMP3 (LineOfBusinessID int)
	insert into #TMP3
	select LineOfBusinessID from #TMP2 
	except 
	select LineOfBusinessID from #TMP1
	
	declare c1 cursor for
		select distinct RtLayerKey from RtroLineOfBusiness where LineOfBusinessID in(select LineOfBusinessID from #TMP3)
	open c1
	fetch c1 into @rtLayrKey 
	while @@fetch_status=0
	begin
		delete from RtroLineOfBusiness where RtLayerKey = @rtLayrKey
		insert into RtroLineOfBusiness (RtLayerKey,LineOfBusinessID) values(@rtLayrKey,0)
		fetch c1 into @rtLayrKey 
	end
	close c1
	deallocate c1

end
