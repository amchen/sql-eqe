if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_DeleteExposureBrowserInfo') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_DeleteExposureBrowserInfo
end
go

create  procedure absp_DeleteExposureBrowserInfo @nodeKey int,@nodeType int	
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    	MSSQL
Purpose: 	This procedure will accept NodeKey and NodeType as parameters based 
		on which it will delete the browser information from all the four BrowserInfo 
		tables.

Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

##PD  @nodeKey  ^^ The node for which the browser information is to be generated.
##PD  @nodeType  ^^ The node type for which the browser information is to be generated.

*/
as
BEGIN TRY
	declare @sql varchar(max);
	declare @exposureKeyList varchar(max);
	declare @AccountBrowserDeleted int;
	declare @PolicyBrowserDeleted int;
	declare @LocationBrowserDeleted int;
	declare @LocationConditionBrowserDeleted int;
	
	set @AccountBrowserDeleted=0;
	set @PolicyBrowserDeleted =0;
	set @LocationBrowserDeleted =0;
	set @LocationConditionBrowserDeleted=0;
	
	 --Get all exposure for PPort/Program--
	if @nodeType = 2 or @nodeType = 7 or @nodeType = 27
	begin
		set @sql = 'select ExposureKey from ExposureMap where ParentKey= ' + cast(@nodeKey as varchar) +' and ParentType=' + cast(@nodeType as varchar);
	    	execute   absp_Util_GenInList @exposureKeyList output,@sql,'N';
	end
	
	--Delete in chunks--
	while(1=1)
	begin
	
		--Delete from AccountBrowserInfo--
		if @AccountBrowserDeleted=0
		begin
			set @sql = 'delete top(50000) from AccountBrowserInfo where ExposureKey ' + @exposureKeyList 
			execute(@sql)
			if @@rowcount=0 set @AccountBrowserDeleted=1
		end
		
		--Delete from PolicyBrowserInfo--
		if @PolicyBrowserDeleted=0
		begin
			set @sql = 'delete top(50000)  from PolicyBrowserInfo where ExposureKey ' + @exposureKeyList 
			execute(@sql)
			if @@rowcount=0 set @PolicyBrowserDeleted=1
		end
		
		--Delete from LocationBrowserInfo--
		if @LocationBrowserDeleted=0
		begin
			set @sql = 'delete top(50000) from LocationBrowserInfo where ExposureKey ' + @exposureKeyList 
			execute(@sql)
			if @@rowcount=0 set @LocationBrowserDeleted=1
		end
	
		--Delete from LocationConditionBrowserInfo--
		if @LocationConditionBrowserDeleted=0 
		begin
			set @sql = 'delete  top(50000) from LocationConditionBrowserInfo where ExposureKey ' + @exposureKeyList 
			execute(@sql)
			if @@rowcount=0 set @LocationConditionBrowserDeleted=1
		end
		
		if (@AccountBrowserDeleted=1 and @PolicyBrowserDeleted=1 and @LocationBrowserDeleted=1 and @LocationConditionBrowserDeleted=1)
			break
		end
END TRY

BEGIN CATCH
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH