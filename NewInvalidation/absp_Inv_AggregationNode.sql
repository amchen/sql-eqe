if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Inv_AggregationNode') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Inv_AggregationNode 
end
go

create  procedure  absp_Inv_AggregationNode  @rdbInfoKey int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:  	This procedure will invalidate a given Aggregation Node


Returns: Nothing.
=================================================================================
</pre>
</font>
##BD_END

 */
as
begin
	declare @yltId int
	declare @portDataTableName nvarchar(255)
	declare @sql nvarchar(255)

	set nocount on

	-- get the YLTIDs of interest
	DECLARE db_cursor CURSOR FOR 
		select YLTID from YLTSummary with(nolock) where RdbInfoKey = @rdbInfoKey
		
	OPEN db_cursor  
	FETCH NEXT FROM db_cursor INTO @yltId
	WHILE @@FETCH_STATUS = 0
	begin	 
		if @yltId > 0
			begin
				-- drop the port data table
				set @portDataTableName = 'YLTPortData_' + LTrim(Rtrim(CAST(@yltId as CHAR(255))))
				set @sql = N'drop table ' + @portDataTableName

				if exists(select * from SYSOBJECTS where ID = object_id(@portDataTableName) and objectproperty(ID,N'IsTable') = 1)
				begin
					exec sp_executesql @sql
				end	
			
				-- delete associated results
				delete ResYLTAEP where YLTID = @yltId
				delete ResYLTEAL where YLTID = @yltId
				delete ResYLTELT where YLTID = @yltId
				delete ResYLTOEP where YLTID = @yltId
				delete YLTModelVersion where YLTID = @yltId
				
				-- remove available reports and the summary
				delete RdbAvailableReport where YLTID = @yltId
				delete YLTSummary where YLTID = @yltId
		end
		FETCH NEXT FROM db_cursor INTO @yltId
	end
	CLOSE db_cursor  
	DEALLOCATE db_cursor 
end
