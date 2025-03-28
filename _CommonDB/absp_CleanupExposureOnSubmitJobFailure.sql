if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CleanupExposureOnSubmitJobFailure') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_CleanupExposureOnSubmitJobFailure;
end
go

create procedure absp_CleanupExposureOnSubmitJobFailure
	@exposureKey int
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:       The procedure cleans up the Exposure related tables for the given exposureKey.
Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/

begin

    set nocount on;

	delete ExposureMap where ExposureKey = @exposureKey;
	delete ExposureInfo where ExposureKey = @exposureKey;
	delete ExposureFile where ExposureKey = @exposureKey;
	delete ExposureTemplate where ExposureKey = @exposureKey;
end
