if exists(select * from sysobjects where id = object_id(N'absp_getRdbNameForLock') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_getRdbNameForLock
end
 go
create procedure absp_getRdbNameForLock @lockNodeKey int = 0, @lockNodeType int = 0
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return the databaseName for a rdb if lock info matches

Returns:      DatabaseName

====================================================================================================
</pre>
</font>
##BD_END

##PD  @lockNodeKey    ^^  Lock node key
##PD  @lockNodeType   ^^  Lock node type


*/

BEGIN
	SET NOCOUNT ON;

	declare @rdbInfoKey int;
	declare @rdbNodeType int;
	declare @childRDBNodeType int;
	declare @rdbLongName varchar(200);
		
	select @rdbInfoKey = RdbInfo.RdbInfoKey, @rdbNodeType = RdbInfo.NodeType, @rdbLongName = RdbInfo.LongName from dbo.RdbInfo inner join RdbNodeTypeDef on  RdbNodeTypeDef.NodeType = RdbInfo.NodeType where RdbInfoKey = 1 and RdbInfo.NodeType = 101;
	
	if @lockNodeKey = @rdbInfoKey and @lockNodeType = @rdbNodeType 
	begin
		select @rdbLongName as databaseName;
		return;
	end
	
	declare  c1 cursor for select distinct(NodeType) from dbo.RdbInfo where RdbInfoKey > 1;
	open c1;
	fetch c1 into @childRDBNodeType;
	while @@fetch_status=0
	begin
		if @childRDBNodeType = 102
		begin
			select @rdbInfoKey = RdbInfo.RdbInfoKey, @rdbNodeType = RdbInfo.NodeType, @rdbLongName = RdbInfo.LongName from dbo.RdbInfo inner join RdbNodeTypeDef on  RdbNodeTypeDef.NodeType = RdbInfo.NodeType where RdbInfo.NodeType = 102 and RdbInfoKey > 1 Order By LongName;
			
			if @lockNodeKey = @rdbInfoKey and @lockNodeType = @rdbNodeType 
			begin
				select @rdbLongName as databaseName;
				return;
			end
		end
		
		else if @childRDBNodeType = 103
		begin
			select RdbInfo.*,RdbNodeTypeDef.Description as rdbNodetypeDesc  from dbo.RdbInfo inner join RdbNodeTypeDef on  RdbNodeTypeDef.NodeType = RdbInfo.NodeType where RdbInfo.NodeType = 103 and RdbInfoKey > 1 Order By LongName;
		
			if @lockNodeKey = @rdbInfoKey and @lockNodeType = @rdbNodeType 
			begin
				select @rdbLongName as databaseName;
				return;
			end
		end
	end
	close c1;
	deallocate c1;
	
	-- If no match is found return empty resultset to satisfy hibernate
	select '' as databaseName
	
END
