if exists(SELECT * from SYSOBJECTS where ID = object_id(N'absp_GetOffLineMode') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetOffLineMode
end
go
 
create procedure [dbo].[absp_GetOffLineMode]   @nodeKey integer, @databaseName varchar(120) =''
as
BEGIN
	
	declare @setting int;
	
	EXEC absp_InfoTableAttribGetOffLineMode @setting output,@nodeKey,@databaseName
	print @setting
	if(@setting is null)set @setting = 0
	select @setting as setting

END

