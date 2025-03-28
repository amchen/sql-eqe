if   exists(select 1 from SYSOBJECTS where ID = object_id (N'absp_DeleteAggregationNode') and objectproperty(ID, N'IsProcedure') = 1)
begin
    drop  procedure  absp_DeleteAggregationNode
end
go

create  procedure  absp_DeleteAggregationNode  @dbRefKey int, @rdbInfoKey int, @nodeType int    
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:   MSSQL
Purpose:      This procedure will accept RdbInfoKey and NodeType as parameters based
              on which it will delete aggregation node details from all related tables.

Returns:      Nothing.
=================================================================================
</pre>
</font>
##BD_END

##PD  @@dbRefKey  ^^ The dbRef Key
##PD  @rdbInfoKey  ^^ The key for which the aggregation data has to be deleted
##PD  @nodeType    ^^ The aggregation node type

*/
as
BEGIN
      declare  @sql varchar(max);
   
	--Delete all results tables for the given RdbInfoKey--
	exec absp_Inv_AggregationNode @rdbInfoKey;
   
      set  @sql = 'delete from YLTSummary where RdbInfoKey = ' + dbo.trim(cast(@rdbInfoKey as varchar(10)));
      execute (@sql)
   
      set  @sql = 'delete from AggInputSources where RdbInfoKey = ' + dbo.trim(cast(@rdbInfoKey as varchar(10)));
      execute (@sql)
   
      set  @sql = 'delete from TreatyLayer where TreatyId in (select TreatyID from Treaty where RdbInfoKey = ' + dbo.trim(cast(@rdbInfoKey as varchar(10))) + ')' ;
      execute (@sql)
   
      set  @sql = 'delete from Treaty where RdbInfoKey = ' + dbo.trim(cast(@rdbInfoKey as varchar(10)));
	execute (@sql)

	set  @sql = 'delete from DownloadInfo where DBRefKey = ' + dbo.trim(cast(@dbRefKey as varchar(30))) + ' and RdbInfoKey = ' + dbo.trim(cast(@rdbInfoKey as varchar(30))) + ' and NodeType = ' + dbo.trim(cast(@nodeType as varchar(10)));
	execute (@sql)
	
  	set  @sql = 'delete from TaskInfo where DBRefKey = ' + dbo.trim(cast(@dbRefKey as varchar(30))) + ' and RdbInfoKey = ' + dbo.trim(cast(@rdbInfoKey as varchar(30))) + ' and NodeType = ' + dbo.trim(cast(@nodeType as varchar(10)));
      execute (@sql)
   
      set  @sql = 'delete from RdbInfo where RdbInfoKey = ' + dbo.trim(cast(@rdbInfoKey as varchar(10))) + ' and NodeType = ' + dbo.trim(cast(@nodeType as varchar(10)));
      execute (@sql)
   
END