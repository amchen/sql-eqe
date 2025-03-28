if exists(select 1 from SYSOBJECTS where id = object_id(N'absp_Migr_RenameTable') and objectproperty(ID,N'IsProcedure') = 1)
begin
    drop procedure absp_Migr_RenameTable
end
go

create procedure  absp_Migr_RenameTable @tableName varchar(200),@newTableName varchar(200)
as
begin
	declare @sSql varchar(2000)
	declare @objName nvarchar(2000)
	declare @newName nvarchar(2000)
	
	set @sSql = 'exec sp_rename ' + @tableName+',' + @newTableName
	exec (@sSql)
	
	set @objName = ''
	select top(1) @objName= name from sys.indexes where OBJECT_NAME(object_id)=@newTableName and name like '%[_]PK'
    	if @objName <>''
    	begin
		set @newName = dbo.trim(@newTableName) + '_PK'
    		exec sp_rename @objName, @newName, N'OBJECT';
   	 end

end

