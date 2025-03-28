if exists(select * from SYSOBJECTS where ID = object_id(N'absp_IsAportfolioReadyForAnalysis') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_IsAportfolioReadyForAnalysis
end
 go

create procedure absp_IsAportfolioReadyForAnalysis @aportKey int

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure check whether APort has any children and whether the child PPort or
Program or Reinsurance Account is imported or not i.e. ExposureMap has any entry
with those nodeKey, nodeType.

Returns:

=================================================================================
</pre>
</font>
##BD_END

##BPD  @aportKey ^^ The key of the aport for which it is to be checked if it requires analysis.

##RD  @count ^^ The number of exposureKey of aport's children whose status is 'Importted'.

*/
as
begin

   set nocount on

   declare @count int
   declare @sql nvarchar(max)
   declare @exposureKeyListForPPort varchar(1000)
   declare @exposureKeyListForRPort varchar(1000)
   declare @allExposureKeyList varchar(2000)

   set @sql = 'select exposureMap.exposureKey from rportmap inner join exposureMap on exposureMap.parentKey = rportmap.child_Key
	inner join aportmap on rportmap.rport_key = aportmap.child_key
	inner join proginfo on proginfo.prog_key = exposureMap.parentKey
	inner join caseInfo on proginfo.prog_key = caseInfo.prog_key
	and (parentType = 7 or parentType = 27) and (aportmap.child_type = 3 or aportmap.child_type = 23)
	and aportmap.aport_key = ' + dbo.trim(str(@aportKey))

   execute absp_util_genInListString @exposureKeyListForRPort output, @sql

   set @sql = 'select exposureKey from aportmap inner join exposureMap on exposureMap.parentKey = aportmap.child_Key
   	and parentType = 2 and aportmap.child_type = 2
   	and aportmap.aport_key = ' + dbo.trim(str(@aportKey))

   execute absp_util_genInListString @exposureKeyListForPPort output, @sql

   if(len(@exposureKeyListForRPort) > 0)
   	set @allExposureKeyList = @exposureKeyListForRPort
   else if(len(@exposureKeyListForPPort) > 0)
   	set @allExposureKeyList = @exposureKeyListForPPort
   else if(len(@exposureKeyListForPPort) > 0 and len(@exposureKeyListForRPort) > 0)
	set @allExposureKeyList = @exposureKeyListForRPort + ', ' + @exposureKeyListForPPort

   set @sql = 'select @count = count(*) from exposureInfo where exposureKey in (' + dbo.trim(@allExposureKeyList) +')
   and (exposureInfo.status = ''Imported'' or exposureInfo.status = ''Oakland'')'

   execute sp_executesql @sql,N'@count int output', @count output

   return @count
end





