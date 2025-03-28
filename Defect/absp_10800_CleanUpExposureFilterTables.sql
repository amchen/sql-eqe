if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_10800_CleanUpExposureFilterTables') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_10800_CleanUpExposureFilterTables
end
 go

create procedure absp_10800_CleanUpExposureFilterTables
as
begin
	--0010800: Migration needs to drop the exposure browser filtered tables (eg FilteredAccount_1_2_1)
	declare @nodeType int;
	declare @nodeKey int;
	declare @schemaName varchar(120);

	declare curNode cursor for 
		select Pport_Key,2  from Pprtinfo
		union
		select Prog_Key,27 from ProgInfo 
	
	open curNode
	fetch curNode into @nodeKey,@nodeType
	while @@fetch_status=0
	begin
		--Drop Filetered tables and FilteredStatReport
		exec absp_CleanUpBrowserData @nodeKey, @nodeType,1

		--Delete Filter and sort infomatin
		delete from ExposureDataFilterInfo where NodeKey=@nodeKey and NodeType=@nodeType
		delete from ExposureDataSortInfo where NodeKey=@nodeKey and NodeType=@nodeType

		fetch curNode into @nodeKey,@nodeType
	end
 
end
