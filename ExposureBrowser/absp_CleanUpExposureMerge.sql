if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_CleanUpExposureMerge') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_CleanUpExposureMerge
end
go

create  procedure absp_CleanUpExposureMerge  @nodeKey int=-1,@nodeType int=-1, @exposureKey int=-1
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================

DB Version:    	MSSQL

Purpose: 	The procedure will cleanup data from the BrowserInfo tables on failure.


Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

##PD  @nodeKey  ^^ The nodekey for which data cleanup is needed
##PD  @nodeType  ^^ The nodeType
##PD  @exposureKey  ^^ The exposure key for which data cleanup is needed


*/
as
begin
	set nocount on;
	declare @sql varchar(max);
	declare @tName varchar(120)
	
	if @exposureKey=-1
		declare c1 cursor forward_only   for 
			select T1.ExposureKey from ExposureInfo T1 inner join ExposureMap T2 on T1.ExposureKey=T2.ExposureKey 
			and T2.ParentKey = @nodeKey and T2.ParentType = @nodeType
	else
		declare c1 cursor forward_only  for select @exposureKey
	open c1
	fetch c1 into @exposureKey
	while @@fetch_status=0
	begin
		--Drop the temporary tables to be merged--
		declare c2 cursor fast_forward for select name from SYS.TABLES where name like 'AccountBrowserInfo_' + dbo.trim(cast(@exposureKey as varchar(50))) +'_%'
		union 
		select name from SYS.TABLES where name like 'PolicyBrowserInfo_' + dbo.trim(cast(@exposureKey as varchar(50))) +'_%'
		union
		select name from SYS.TABLES where name like 'LocationBrowserInfo_' + dbo.trim(cast(@exposureKey as varchar(50))) +'_%'
		union
		select name from SYS.TABLES where name like 'LocationConditionBrowserInfo_' + dbo.trim(cast(@exposureKey as varchar(50))) +'_%'
		open c2 
		fetch c2 into @tName
		while @@fetch_status=0
		begin
			exec('drop table ' + @tName)
			fetch c2 into @tName
		end
		close c2
		deallocate c2
		
		
		--Cleanup BrowserInfo tables only if isBrowserDataGenerated flag is false--
		if exists (select 1  from exposureinfo where exposureKey=@exposureKey and isBrowserDataGenerated='N')
		begin
			delete from AccountBrowserInfo where exposureKey=@exposureKey
			delete from PolicyBrowserInfo where exposureKey=@exposureKey
			delete from LocationBrowserInfo where exposureKey=@exposureKey
			delete from LocationConditionBrowserInfo where exposureKey=@exposureKey
		end
		
		fetch c1 into @exposureKey
	end
	close c1
	deallocate c1 
end



   		
