if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetFilteredTableName') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetFilteredTableName
end
 go

create procedure absp_GetFilteredTableName @tableName varchar(200) output,@category varchar(50), @nodeKey int, @nodeType int, @userKey int=1
as
begin
	
	set @tableName='Filtered' + @category + '_' + dbo.trim(cast(@userKey as varchar(10))) + '_'+dbo.trim(cast(@nodeType as varchar(10))) + '_'+dbo.trim(cast(@nodeKey as varchar(10)))
	
end
