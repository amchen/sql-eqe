if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GenerateExposureBrowserInfo') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GenerateExposureBrowserInfo
end
go

create  procedure absp_GenerateExposureBrowserInfo @exposureKey int	
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    	MSSQL
Purpose: 	This is the high level procedure which will call the procedures to generate Account, 
         	Policy and Location browser information. This procedure will get called as the last step in 
         	the import process. 


Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

##PD  @exposureKey  ^^ The exposure for which the browser information is to be generated.
 
*/
as
begin
	print convert(varchar,GetDate(),121)
	execute absp_GenerateAccountBrowserInfo @exposureKey
	print convert(varchar,GetDate(),121)
	execute absp_GeneratePolicyBrowserInfo @exposureKey
	print convert(varchar,GetDate(),121)
	execute absp_GenerateLocationBrowserInfo @exposureKey
	print convert(varchar,GetDate(),121)
	execute absp_GenerateLocationConditionBrowserInfo @exposureKey
	print convert(varchar,GetDate(),121)
	
	--update ExposureInfo --
	--update ExposureInfo 
		--set IsBrowserDataGenerated='Y'
	--where ExposureKey=@exposureKey
end