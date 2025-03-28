if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewGetChildNodesCount') and objectproperty(ID,N'IsProcedure') = 1)
begin
	drop procedure absp_TreeviewGetChildNodesCount
end
go
create procedure absp_TreeviewGetChildNodesCount @currentNodeKey int, @currentNodeType int, @parentNodeKey int
as

-- This procedure will return the count of all the childs under a given node.

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:

		This procedure returns the count of children under a specified tree node.


Returns:       	A single value @childNodeCount


====================================================================================================
</pre>
</font>
##BD_END

##PD @currentNodeKey     ^^  The key for the node to have its child nodes counted.
##PD @currentNodeType    ^^  The type of the node to have its child nodes counted.
##PD @parentNodeKey     ^^   The pport key, only used for node type = 8.
##RD @childNodeCount 	 ^^  The count for the number of children under the specified node.

*/

begin
 
   set nocount on
   
       --Folder = 0;
        --APort = 1;
        --PPort = 2;
        --RPort = 3;
        --Prog = 7;
        --Lport = 8;
        --Mtrport = 23;
        --Mtprog = 27;

	declare @sSql nvarchar(1024)
        declare @childNodeCount int
        set @childNodeCount  = 0

       	-- Call the correct counter based on the child type
       	select  @sSql = case   
	
       	-- Folder
       	when  @currentNodeType = 0  then
        'select @childNodeCount =count(*) from FLDRMAP where FOLDER_KEY = @currentNodeKey'
	
    	-- APort
       	when  @currentNodeType = 1  then
        'select @childNodeCount = count(*) from APORTMAP where APORT_KEY = @currentNodeKey'
	
    	-- Reinsurance
       	when  @currentNodeType = 3 then
        'select @childNodeCount = count(*) from RPORTMAP where RPORT_KEY = @currentNodeKey and CHILD_TYPE = 7'

    	-- Program
       	when  @currentNodeType = 7 then
        'select @childNodeCount = count(*) from CASEINFO where PROG_KEY = @currentNodeKey'

    	-- Multi-Treaty reinsurance
       	when  @currentNodeType = 23 then
        'select @childNodeCount = count(*) from RPORTMAP where RPORT_KEY = @currentNodeKey and CHILD_TYPE = 27'

    	-- Multi-Treaty program
       	when  @currentNodeType = 27 then
        'select @childNodeCount =count(*) from CASEINFO where PROG_KEY = @currentNodeKey'

       end;
       
       exec sp_executesql @sSql,N'@childNodeCount int output,@currentNodeKey int,@parentNodeKey int',@childNodeCount out,@currentNodeKey,@parentNodeKey 
       return  @childNodeCount;
end