if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_UpdateExposureBrowserInfoFlag') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_UpdateExposureBrowserInfoFlag;
end
go

create  procedure absp_UpdateExposureBrowserInfoFlag  @nodeKey int,@nodeType int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================

DB Version:    	MSSQL

Purpose: 	The procedure will update the IsBrowserDataGenerated flag in Exposureinfo table.


Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

##PD  @exposureKey  ^^ The exposure key for which the browser information is to be generated.


*/
as
begin
	set nocount on;
	declare  @expKeyInList varchar(max)
	declare  @sql varchar(max)

	exec absp_Util_GetExposureKeyList @expKeyInList output, @nodeKey, @nodeType;
	set @sql = 'update ExposureInfo
		 		set IsBrowserDataGenerated=''Y''
	where ExposureKey  ' + @expKeyInList + ' and status <> ''Deleted'''

	exec(@sql)
end
