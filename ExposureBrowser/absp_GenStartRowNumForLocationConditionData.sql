if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GenStartRowNumForLocationConditionData') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GenStartRowNumForLocationConditionData
end
go

create procedure [dbo].[absp_GenStartRowNumForLocationConditionData] @nodeKey int=-1, @nodeType int=-1,@chunkSize int
 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL

Purpose:	This procedure returns a resultset having the exposureKey and the startRowNum for each chunk.

Returns:     A resultset having the exposureKey and the strtRowNum for each chunk.

====================================================================================================

</pre>
</font>
##BD_END

##PD   @nodeKey 	^^  The nodeKey for which the exposures are to be determined
##PD   @nodeType 	^^  The nodeType for which the exposures are to be determined
##PD   @exposureKey 	^^  The exposureKey for which the startRow numbers for chunking are to be determined
##PD   @chunkSize 	^^  The chunk size
 */
as
begin

	set nocount on
	declare @expKey int;
	declare @chunkNum int;
	declare @startRowNum int;
	declare @exposureKeyList nvarchar(max);
	
	--Create table to hold ExposureKeys--
	create table #TMP_EXPOSUREKEYS (ExposureKeys varchar(8000) COLLATE SQL_Latin1_General_CP1_CI_AS) 
	
	-- insert the list of exposureKeys	for given nodekey and nodeType.
	insert into #TMP_EXPOSUREKEYS  exec absp_Util_GetExposureKeyList_RS  @nodeKey,@nodeType
	select @exposureKeyList=ExposureKeys from #TMP_EXPOSUREKEYS
	
	--absp_Util_GetExposureKeyList_RS  ResultSet like  in ( exposureKey ,exposureKey ,exposureKey) 
	set @exposureKeyList=REPLACE(@exposureKeyList,'(','')
	set @exposureKeyList=REPLACE(@exposureKeyList,'in','')
	set @exposureKeyList=ltrim(rtrim(REPLACE(@exposureKeyList,')','')))
	
	drop table #TMP_EXPOSUREKEYS;
	--Create table to hold StartrowNum--
	create table #TMP_STARTROWNUM (ExposureKey int, ChunkNum int, StartRowNum int);
		
	-- 	 split the all exposureKeys and stored in cursor
	declare c2 cursor fast_forward for  SELECT SUBSTRING(',' + @exposureKeyList + ',', Number + 1, 
    CHARINDEX(',', ',' + @exposureKeyList + ',', Number + 1) - Number -1)AS ExposureKeyValue
    FROM master..spt_values 
    WHERE Type = 'P' 
    AND Number <= LEN(',' + @exposureKeyList + ',') - 1 
    AND SUBSTRING(',' + @exposureKeyList + ',', Number, 1) = ',' 
	
	open c2
	fetch c2 into @expKey	
	while @@fetch_status=0
	begin	
			begin
				insert into #TMP_STARTROWNUM exec  absp_GenStartRowNumForLocationCondition  -1,@nodeType, @expKey,@chunkSize
			end
		
    fetch c2 into @expKey
	end
	close c2
	deallocate c2
	
	--Return resultset--
	select ExposureKey, ChunkNum, StartRowNum from #TMP_STARTROWNUM  order by ExposureKey,ChunkNum,StartRowNum
end