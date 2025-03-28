if exists(select * from SYSOBJECTS where ID = object_id(N'absp_IsParentOrChildInvalidating') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_IsParentOrChildInvalidating
end

go

create  procedure absp_IsParentOrChildInvalidating  @result bit output, 
													@nodeKey int, 
													@nodeType int,
													@extraKey integer = -1

/* 
##BD_BEGIN  
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose:	   This procedure checks if the given portfolio has an invalidating parent or child
			   and returns 0 or 1 accordingly in an output parameter.

Returns:      Output Parameter - 
			  0 if none of the node's parent or child nodes are invalidating 
			  1 if any of the node's parent or child nodes is invalidating
=================================================================================
</pre> 
</font> 
##BD_END 

##PD  @result ^^ If any of the parent or child nodes are invalidating, it returns 0 else 1 .
##PD  @nodeKey ^^ Key for the invalidating portfolio.
##PD  @nodeType ^^ Invalidating portfolio node type.

*/

as

BEGIN TRY
set nocount on

	declare @sql varchar (2000)
	declare @msg varchar(4000)
	declare @me varchar(100)
	declare @node_key varchar(100)
	declare @node_type varchar(100)
	
	set @me = 'absp_IsParentOrChildInvalidating'
	set @msg = @me + ' Starting...'
	exec absp_MessageEx @msg
	
	set @result = 0
	
	--Create a temporary table to get the list of all parent and child nodes--
	create table #NODELIST (NODE_KEY INT, NODE_TYPE INT, PARENT_KEY INT, PARENT_TYPE INT)
	
	-- get all parent nodes
	execute absp_PopulateParentList @nodeKey, @nodeType, @extraKey
	
	-- get all child nodes
  	execute absp_PopulateChildList @nodeKey, @nodeType
  	
  	--If any of the parent or chid node is invalidating return 1--
  	declare curs1 cursor local for select NODE_KEY,NODE_TYPE from #NODELIST 
	open curs1
	fetch curs1 into @node_key, @node_type 
	while @@fetch_status=0
	begin
		--Check if invalidating
		exec absp_InfoTableAttribGetInvalidating  @result out, @node_type ,@node_key
		if @result = 1 
			break
		fetch curs1 into @node_key, @node_type 
   	end
  	close curs1
  	deallocate curs1
  	set @msg = @me + ' Ending...'
	exec absp_MessageEx @msg

END TRY 
BEGIN CATCH
	declare @ProcName varchar(100)
	select @ProcName=object_name(@@procid)
	exec absp_Util_GetErrorInfo @ProcName
END CATCH