if exists(select * from SYSOBJECTS where ID = object_id(N'absp_007083_CheckAndCreateRDBIndexes') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_007083_CheckAndCreateRDBIndexes;
end
go

create procedure  absp_007083_CheckAndCreateRDBIndexes 
as

begin
	set nocount on
	declare @tablename varchar(130);
	
 	declare c1 cursor for select tableName from systemdb..DictTbl where RDB in('Y','L');
	open c1; 
	fetch c1 into @tableName; 
	while @@FETCH_STATUS =0  
	begin  
		if exists(select 1 from sys.objects where name=@tableName)
			exec absp_007083_CreateNonExistingIndexForTable @tableName; 
		fetch c1 into @tableName; 
	end;
	close c1; 
	deallocate c1;

end;