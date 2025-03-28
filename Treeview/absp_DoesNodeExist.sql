if exists(select * from SYSOBJECTS where ID = object_id(N'absp_DoesNodeExist') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_DoesNodeExist
end
 go

create procedure absp_DoesNodeExist @nodeKeyList varchar(max) ,@nodeType int ,@parentKey int ,@parentType int ,@nodeCount int ,@extraKeyList varchar(255) = '0' --,@SWP_Ret_Value int output 
AS
/* 
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose: 

The procedure returns 1 if the number of given child nodes under the specified 
parent node matches with the given nodeCount else returns 0.

Returns:       1 is returned if the number of given child nodes under the specified 
parent node matches with the given nodeCount else returns 0.
=================================================================================
</pre> 
</font> 
##BD_END 

##PD  nodeKeyList ^^ The comma delimited list of child node keys. However,there are two exceptions. If the parent type is 2 (PPort), nodeKeyList must have the format: (policy_key=KEY1 and port_id=PID1) or (policy_key=KEY2 and port_id=PID2) or (...). If the parent type is 3 (Policy), nodeKeyList must have the format: (site_key=KEY1 and port_id=PID1) or (site_key=KEY2 and port_id=PID2) or (...)
##PD  nodeType ^^ The type of child node.
##PD  parentKey ^^ The key of the parent node.
##PD  parentType ^^ The type of the parent node.
##PD  nodeCount ^^ The count of child nodes under the given parent.
##PD  extraKeyList ^^ Unused Parameter.

##RD @retVal ^^ Returns 1 if the number of given child nodes under the specified 
parent node matches with the given nodeCount else returns 0.

*/
begin

   set nocount on
   
  --Folder = 0;
  --APort = 1;
  --PPort = 2;
  --RPort = 3;
  --Prog = 7;
  --policy = 8;
  --site = 9;
  --case = 10;
  --currency = 12;
  --MT_RPORT = 23
  --MT_PROG = 27
   declare @count int
   declare @query varchar(max)
   declare @debug int
   declare @retVal int
   declare @msgText varchar(max)
   declare @strNodeType char(10);
   declare @strParentKey char(10);
   declare @SWV_exec nvarchar(max)
   set @debug = 0
   set @count = 0
   set @query = ''
   if(@debug > 0)
   begin
      set @msgText = 'absp_DoesNodeExist: nodeType  = '+str(@nodeType)
      execute absp_messageEx @msgText
      set @msgText = 'absp_DoesNodeExist: parentType  = '+str(@parentType)
      execute absp_messageEx @msgText
   end
   
   -- call the correct lister based on the parent NodeType
	set @nodeKeyList = rtrim(ltrim(@nodeKeyList))
	set @strNodeType = rtrim(ltrim(str(@nodeType)))
	set @strParentKey = rtrim(ltrim(str(@parentKey)))
	
	select @query = 
		case @parentType
		
		when 0 then 
			'select @count = count(*) from FLDRMAP where CHILD_KEY in(' + @nodeKeyList + ') and CHILD_TYPE = ' + @strNodeType + ' and FOLDER_KEY = ' + @strParentKey
		when 1 then
			'select @count = count(*) from APORTMAP where CHILD_KEY in(' + @nodeKeyList + ') and CHILD_TYPE = ' + @strNodeType + ' and APORT_KEY = ' + @strParentKey	   
		when 3 then
			'select @count = count(*) from RPORTMAP where CHILD_KEY in(' + @nodeKeyList + ') and CHILD_TYPE = ' + @strNodeType + ' and RPORT_KEY = ' + @strParentKey
		when 23 then
			'select @count = count(*) from RPORTMAP where CHILD_KEY in(' + @nodeKeyList + ') and CHILD_TYPE = ' + @strNodeType + ' and RPORT_KEY = ' + @strParentKey
		when 7 then
			'select @count = count(*) from CASEINFO where CASE_KEY in(' + @nodeKeyList + ') and PROG_KEY = ' + @strParentKey
		when 27 then       
			'select @count = count(*) from CASEINFO where CASE_KEY in(' + @nodeKeyList + ') and PROG_KEY = ' + @strParentKey
		when 12 then
			'select @count = count(*)  from FLDRMAP where CHILD_KEY in(' + @nodeKeyList + ') and CHILD_TYPE = ' + @strNodeType + ' and FOLDER_KEY = 0'
	end
	        
   if(@debug > 0)
   begin
      set @msgText = 'absp_DoesNodeExist: query  = '+@query
      execute absp_messageEx @msgText
   end
  -- SDG__00015260 - turn on the check to avoid SQL exception if @query is empty
   if len(@query) > 0
   begin
     -- execute @query
     set @SWV_exec = @query
     execute sp_executesql @SWV_exec,N'@COUNT int output',@COUNT output
   end
   if(@debug > 0)
   begin
      set @msgText = 'absp_DoesNodeExist: count  = '+str(@count)
      execute absp_messageEx @msgText
   end
   if @count = @nodeCount
   begin
      set @retVal = 1
   end
   else
   begin
      set @retVal = 0
   end
   --set @SWP_Ret_Value = @retVal
   return @retVal
end


