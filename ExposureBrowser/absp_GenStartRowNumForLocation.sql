if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GenStartRowNumForLocation') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GenStartRowNumForLocation
end
go

create procedure absp_GenStartRowNumForLocation @nodeKey int=-1, @nodeType int=-1, @exposureKey int=-1,@chunkSize int
 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL

Purpose:	This procedure returns a resultset having the exposureKey and the strtRowNum for each chunk.

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
	declare @startRowNum int;
	declare @chunkNum int;
	declare @expKey int;
	declare @cnt int;
	
	set @chunkNum=1;
	set @startRowNum=0;
	
	--Create table to hold StartrowNum--
	create table #TMP_STARTROWNUM (ExposureKey int, ChunkNum int, StartRowNum int);
	
	if @nodeKey<>-1
		declare c1 cursor fast_forward for select ExposureKey from ExposureMap where ParentKey= @nodeKey and ParentType=@nodeType;
	else
		declare c1 cursor fast_forward for select @exposureKey
	open c1
	fetch c1 into @expKey	
	while @@fetch_status=0
	begin	
		--Get the minimum StartRowNum for the exposureKey--
		--select  @startRowNum= isnull(min(StructureRowNum),-1) from Structure where ExposureKey = @expKey option (recompile);
		--insert into #TMP_STARTROWNUM values(@expKey,@chunkNum,@startRowNum)
		----if @startRowNum<>-1
		--begin
			while(1=1)
			begin
				select top(1) @startRowNum=StructureRowNum from   Structure 
					where exposureKey=@expKey and StructureRowNum > @startRowNum  order by StructureRowNum option (recompile)
				
				if @@rowcount=0 break
				insert into #TMP_STARTROWNUM values(@expKey,@chunkNum,@startRowNum)	
				set @startRowNum = @startRowNum+ @chunkSize-1
				set @chunkNum=@chunkNum + 1
			end
		----end
		fetch c1 into @expKey
	end
	close c1
	deallocate c1
	
	--Return resultset--
	select ExposureKey, ChunkNum, StartRowNum from #TMP_STARTROWNUM  order by exposureKey,ChunkNum,StartRowNum
end
