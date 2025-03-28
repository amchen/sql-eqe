if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetOffShorePolicyConditionName') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetOffShorePolicyConditionName
end
 go

create procedure absp_GetOffShorePolicyConditionName @tableName varchar(1000),@nodeKey int,@nodeType int
as
begin
	set nocount on
	
 	
	declare @Coverage varchar(max);
	declare @pKey int;
	declare @sql varchar(max);
	declare @sql2 varchar(max);
	
	select ExposureMap.ExposureKey,FinancialModelType into #EXP from ExposureMap inner join ExposureInfo on ExposureMap.ExposureKey=ExposureInfo.ExposureKey
		where ParentKey= @nodeKey and ParentType=@nodeType;

	declare cu1 cursor  for 
		select PolicyConditionKey from PolicyCondition A 
			inner join #EXP B on A.ExposureKey=B.ExposureKey
			where coverOrderOffShore>0 group By PolicyConditionKey having count(*)>0
	open cu1
	fetch cu1 into @pKey
	while @@fetch_Status=0
	begin		
		select @Coverage=COALESCE(@Coverage+'+' , '') + U_Cover_ID  
			from PolicyCondition A inner join CIL B on A.CoverageID=B.Cover_ID 
			inner join #EXP C on A.ExposureKey=C.ExposureKey
			where PolicyConditionKey=@pKey and CoverOrderOffshore>0 order by CoverOrderOffshore;

		set @sql2='update ' + @tableName +' set CSLCoverageName=''' + @Coverage + 
		''' from ' + @tableName + ' A '+
		' inner join PolicyCondition B ' +
		' on A.PolicyConditionRowNum=B.PolicyConditionRowNum '+
		' where PolicyConditionKey=' + cast(@pKey as varchar(30)) 
		exec (@sql2);


		set @Coverage=null;
		fetch cu1 into @pKey
	end
	close cu1
	deallocate cu1

end
