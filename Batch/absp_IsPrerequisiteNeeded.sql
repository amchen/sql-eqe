if exists(select 1 FROM SYSOBJECTS WHERE id = object_id(N'absp_IsPrerequisiteNeeded') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_IsPrerequisiteNeeded;
end
go

create procedure absp_IsPrerequisiteNeeded
	@nodeKey int,
	@nodeType int
as
/*
====================================================================================================
Purpose:	This procedure checks if there are prerequisites needed for this NodeKey, NodeType by
			querying migration special info tables.
Returns:	Result set of prerequisites that are needed for this NodeKey, NodeType.
====================================================================================================
*/
begin
	set nocount on;

	declare @progKey int;
	declare @prereq table (MigrationSpecialInfoKey int, Description varchar(200));

	-- create temp table to populate in absp_PopulateChildList
	create table #NODELIST (NODE_KEY INT, NODE_TYPE INT, PARENT_KEY INT, PARENT_TYPE INT);

	-- If this is a Treaty node, use the parent Program node
	if (@nodeType = 30)
	begin
		select distinct @progKey = Prog_Key from CaseInfo where Case_Key = @nodeKey;
		set @nodeKey = @progKey;
		set @nodeType = 27;
	end

	-- get all child nodes and populate #NODELIST
  	execute absp_PopulateChildList @nodeKey, @nodeType;

	-- insert record for self
	insert #NODELIST (NODE_KEY,NODE_TYPE) values (@nodeKey, @nodeType);

	-- remove non-Exposure parents
	delete from #NODELIST where NODE_TYPE not in (2,7,27);

	-- check LookupMigrationInfo
	if exists (select 1 from LookupMigrationInfo t1 inner join #NODELIST t2 on t1.ParentKey = t2.NODE_KEY and t1.ParentType = t2.NODE_TYPE and t1.FinishDate = '')
		insert @prereq (MigrationSpecialInfoKey, Description)
			select MigrationSpecialInfoKey, Description from systemdb..MigrationSpecialInfo where MigrationSpecialInfoKey = 2;

	-- check RegeocodeInfo
	if exists (select 1 from RegeocodeInfo t1 inner join #NODELIST t2 on t1.ParentKey = t2.NODE_KEY and t1.ParentType = t2.NODE_TYPE and t1.FinishDate = '')
		insert @prereq (MigrationSpecialInfoKey, Description)
			select MigrationSpecialInfoKey, Description from systemdb..MigrationSpecialInfo where MigrationSpecialInfoKey = 3;

	-- check for No prerequisites
	if not exists (select 1 from @prereq)
		insert @prereq (MigrationSpecialInfoKey, Description)
			select MigrationSpecialInfoKey, Description from systemdb..MigrationSpecialInfo where MigrationSpecialInfoKey = 0;

	-- output result set
	select * from @prereq order by MigrationSpecialInfoKey;
end
