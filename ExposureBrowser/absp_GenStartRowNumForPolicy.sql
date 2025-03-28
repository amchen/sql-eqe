if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GenStartRowNumForPolicy') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GenStartRowNumForPolicy
end
go

create procedure absp_GenStartRowNumForPolicy @nodeKey int=-1, @nodeType int=-1, @exposureKey int=-1,@chunkSize int
 
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
	declare @startRowNum int;
	declare @chunkNum int;
	declare @expKey int;
	declare @cnt int;
	
	set @chunkNum=1;
	
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
		select  @startRowNum= isnull(min(PolicyRowNum),-1) from Policy where ExposureKey = @expKey option (recompile);
		if @startRowNum<>-1
		begin
			while(1=1)
			begin
				insert into #TMP_STARTROWNUM values(@expKey,@chunkNum,@startRowNum)
				set @chunkNum=@chunkNum + 1
				set @startRowNum = @startRowNum+ @chunkSize
		
				set @cnt=-1
				select @cnt=1  from Policy  where ExposureKey = @expKey and PolicyRowNum between @startRowNum and @startRowNum + (@chunkSize-1) option(recompile)
				if @cnt=-1 --Check if we have any other rows - if not exit
					select @cnt=1  from Policy  where ExposureKey = @expKey and PolicyRowNum > @startRowNum + (@chunkSize-1) option(recompile)
					if @cnt=-1
						break ;
			end
		end
		fetch c1 into @expKey
	end
	close c1
	deallocate c1
	
	--Return resultset--
	select ExposureKey, ChunkNum, StartRowNum from #TMP_STARTROWNUM  order by exposureKey,ChunkNum,StartRowNum
end
