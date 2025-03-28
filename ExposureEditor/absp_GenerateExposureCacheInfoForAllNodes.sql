if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GenerateExposureCacheInfoForAllNodes') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GenerateExposureCacheInfoForAllNodes
end
go

create procedure absp_GenerateExposureCacheInfoForAllNodes 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:      	The procedure generates exposure cache information for the all the
		exposureKey.
Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/

begin 
	set nocount on
	
	declare @exposureKey int;
	declare @parentKey int;
	declare @parentType int;

	declare curs  cursor for select exposureKey from ExposureInfo 
	open curs
	fetch next from curs into @exposureKey
	while @@fetch_status = 0
	begin
		select @parentKey=ParentKey,@parentType=ParentType from ExposureMap where ExposureKey=@exposureKey;
		exec absp_InfoTableAttribSetBrowserDataRegenerate @parentType,@parentKey,1
		exec absp_GenerateExposureCacheInfo @exposureKey;
		
		fetch next from curs into @exposureKey;
	end;
	close curs;
	deallocate curs;
end