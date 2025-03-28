if exists(SELECT 1 from SYSOBJECTS where ID = object_id(N'absp_GetExposureKeysForInvalidateLargeTables') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetExposureKeysForInvalidateLargeTables
end
go
 
create procedure absp_GetExposureKeysForInvalidateLargeTables  @nodeType integer, @nodeKey integer, @exposureKey integer = 0  
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure will return all exposure keys under the given portfolio that are marked for invalidate large tables.
     
    	    
Returns: Exposure key list as result set.
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @nodeType ^^ The type of node for which the Invalidating attribute setting are to be set
##PD  @nodeKey ^^  The key of node for which the Invalidating attribute setting are to be set


*/
as
begin
    set nocount on
    declare @attribName  varchar(25)
       declare @attrib integer;
       declare @sql nvarchar(max);
       				
	if @nodeType = 1
	begin
	
		set @sql = 'select ExposureKey from ExposureInfo where InvalidateLargeTables = 1 and ' +
				'ExposureKey in( select distinct ExposureKey from AportMap A inner join RPortMap R on ' +
				'A.Child_Key = R.Rport_Key and A.Child_Type = 23 inner join ExposureMap E on ' +
				'R.Child_Key = E.ParentKey and R.Child_Type = E.ParentType ' +
				'where Aport_Key = ' + str(@nodeKey) + ' ' +
				'union ' +
				'select distinct ExposureKey from AportMap A inner join ExposureMap E on ' +
				'A.Child_Key = E.ParentKey and A.Child_Type= 2 ' +
				'where Aport_Key = ' + str(@nodeKey) + ')'
	
	end
	else if @nodeType = 2
	begin
		set @sql = 'select ExposureKey from ExposureInfo where InvalidateLargeTables = 1 and ' +
				'ExposureKey in(select distinct ExposureKey from ExposureMap E ' +
				'where E.ParentType = 2 and E.ParentKey = ' + str(@nodeKey) + ')'
	end
	else if @nodeType = 23
	begin
		set @sql = 'select ExposureKey from ExposureInfo where InvalidateLargeTables = 1 and ' +
				'ExposureKey in(select distinct ExposureKey from RportMap R inner join ExposureMap E on ' +
				'R.Child_Key = E.ParentKey and R.Child_Type = E.ParentType ' +
				'where R.Rport_Key = ' + str(@nodeKey) + ')'
	end
	else if @nodeType = 27
	begin
		set @sql = 'select ExposureKey from ExposureInfo where InvalidateLargeTables = 1 and ' +
				'ExposureKey in(select distinct ExposureKey from ExposureMap E ' +
				'where E.ParentType = 27 and E.ParentKey = ' + str(@nodeKey) + ')'
	end
	else if @nodeType = 4 or @nodeType = 9
	begin
		set @sql = 'select ExposureKey from ExposureInfo where InvalidateLargeTables = 1 and ' +
				'ExposureKey = ' + str(@exposureKey)
	end
	else if @nodeType = 30
	begin
		set @sql = 'select ExposureKey from ExposureInfo where InvalidateLargeTables = 1 and ' +
				'ExposureKey in(select distinct ExposureKey from ExposureMap E inner join CaseInfo C on ' +
				'E.ParentKey = C.Prog_key where E.ParentType = 27 and C.Case_Key = ' + str(@nodeKey) + ')'
	end
	
	print @sql
	exec (@sql);
	
end
