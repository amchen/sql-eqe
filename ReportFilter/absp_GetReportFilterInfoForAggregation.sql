if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetReportFilterInfoForAggregation') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetReportFilterInfoForAggregation
end
 go

create procedure absp_GetReportFilterInfoForAggregation @rdbInfoKey int
as
begin
	set nocount on
		
	--get the distinct list of ModelRegionID for all the YLTID associated with the RDB Node.
	select distinct ModelRegionID into #Lookup from RESYLTELT where YltID in (select YltID from YltSummary where RDBInfoKey=@rdbInfoKey)
	
	select 'RESYLTELT' as TableName, 'ModelRegionCache' as CacheTypeName, ModelRegionID as LookupID, Code as LookupUserCode,Describe as Description ,'N' as DefaultRow
		from #LookUp A inner join Mdl_Regn B
		on A.ModelRegionID=B.Mdl_Rgn_ID

end