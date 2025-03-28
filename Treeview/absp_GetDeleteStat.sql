if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GetDeleteStat') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetDeleteStat
end

go
create procedure absp_GetDeleteStat @nodeKeyList varchar(max) ,@nodeType int ,@isRecursiveCall int = 0 
as
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure finds the number of things that are going to be deleted if the user
tries to delete a node. The return result is based on the node to be deleted. Lets 
pretend that the user is trying to delete a Folder having multiple Accumulation,
Reinsurance, Primary and Reinsurance Account Portfolio under it. This procedure will
return a result set that will look like

0	1		-- has 1 folder i.e. the node to be deleted
1	100		-- has 100 Accumulation Portfolios
2	235		-- has 235 Primary Portfolios
3	450		-- has 450 Reinsurance Portfolios
23	500		-- has 500 Reinsurance Accounts Portfolios
7	1200	-- has 1200 Programs
27	1000	-- has 1000 Accounts
8	10000	-- has 10000 Policies
9	10000	-- has 10000 Sites

Case or Treaty nodes are not taken into account since this nodes are trivial and does
not take any time to get deleted.

Returns:	1) One result set containing the Node_Type and Counts

====================================================================================================

</pre>
</font>
##BD_END

##PD   	@nodeKeyList 	^^ The list of node keys
##PD   	@nodeType	^^ The node type of the specified node
##PD   	@isRecursiveCall	^^ A mode flag (default 0)

##RS	@NodeType	^^ The node type of child nodes
##RS	@Count		^^ Total count of each child node type
*/
begin
   declare @me char(255)
   declare @msg char(255)
   declare @sql varchar(max)
   declare @isTmpTableExists int
   declare @childFolderKeyList varchar(max)
  
   set nocount on;
   
   set @me = 'absp_GetDeleteStat'
   set @sql = ''
   set @isTmpTableExists = 0
   set @childFolderKeyList = ''
   execute absp_Util_Log_HighLevel 'Starting...',@me
  -- Create a temp table to hold all the information
   execute @isTmpTableExists  = absp_Util_CheckIfTableExists '#DEL_STAT'
   if(@isTmpTableExists = 0)
   begin
      create table #DEL_STAT
      (
         NODE_TYPE INT   null,
         COUNT INT   null
      )
   end
  
    -- insert self
    
    -- insert self
    
    -- insert self
   if(@nodeType = 0 or @nodeType = 12)
   begin
      --set @sql = 'select list(CHILD_KEY) into @childFolderKeyList from FLDRMAP where FOLDER_KEY in ('+@nodeKeyList+') and CHILD_TYPE = 0'
      --execute(@sql)
      set @sql = 'select CHILD_KEY from FLDRMAP where FOLDER_KEY in ('+@nodeKeyList+') and CHILD_TYPE = 0'
      exec absp_util_geninlist @childFolderKeyList output, @sql
      set @childFolderKeyList = substring(@childFolderKeyList,6,(len(@childFolderKeyList)-7));
   
    -- recursive call to count child under sub-folder
      if(@childFolderKeyList <>  ' -2147000000')
      begin
         execute absp_GetDeleteStat @childFolderKeyList,0,1
      end
      set @msg = ' Get Count of all childs under Folder'
      execute absp_Util_Log_HighLevel @msg,@me
    -- insert self
      set @sql = 'insert into #DEL_STAT  select '+str(@nodeType)+', count(*) from FLDRINFO where FOLDER_KEY in ('+@nodeKeyList+')'
      execute absp_Util_Log_HighLevel @sql,@me
      execute(@sql)
    -- Get the counts of Folder, APort, PPort, RPort, RPort Accounts 
      set @sql = 'insert into #DEL_STAT select CHILD_TYPE, count(distinct CHILD_KEY)  from FLDRMAP where FOLDER_KEY in ('+@nodeKeyList+') and CHILD_TYPE <> 0 group by CHILD_TYPE'
      execute(@sql)
    -- Get the count of APort, PPort, RPort, RPort Accounts under all APORTs
      set @msg = ' Get Count of all childs under APort that is a child of this folder'
      execute absp_Util_Log_HighLevel @msg,@me
      set @sql = 'insert into #DEL_STAT select APORTMAP.CHILD_TYPE, count(distinct APORTMAP.CHILD_KEY)  from APORTMAP  inner join FLDRMAP on FLDRMAP.CHILD_KEY = APORTMAP.APORT_KEY and FLDRMAP.CHILD_TYPE = 1 where FLDRMAP.FOLDER_KEY in ('+@nodeKeyList+') group by APORTMAP.CHILD_TYPE'
      execute(@sql)
    -- Get the count of all Programs
    -- Need two queries 1 for Folder and 1 for APort
      set @msg = ' Get Count of all RPorts under this folder'
      execute absp_Util_Log_HighLevel @msg,@me
      set @sql = 'insert into #DEL_STAT select RPORTMAP.CHILD_TYPE, count(distinct RPORTMAP.CHILD_KEY)  from RPORTMAP  inner join FLDRMAP on FLDRMAP.CHILD_KEY = RPORTMAP.RPORT_KEY and FLDRMAP.CHILD_TYPE = 3 where FLDRMAP.FOLDER_KEY in ('+@nodeKeyList+') group by RPORTMAP.CHILD_TYPE'
      execute(@sql)
      set @msg = ' Get Count of all RPorts under any child APort under this folder'
      execute absp_Util_Log_HighLevel @msg,@me
      set @sql = 'insert into #DEL_STAT select RPORTMAP.CHILD_TYPE, count(distinct RPORTMAP.CHILD_KEY)  from RPORTMAP  inner join APORTMAP on APORTMAP.CHILD_KEY = RPORTMAP.RPORT_KEY and APORTMAP.CHILD_TYPE = 3 inner join FLDRMAP on FLDRMAP.CHILD_KEY = APORTMAP.APORT_KEY and FLDRMAP.CHILD_TYPE = 1 where FLDRMAP.FOLDER_KEY in ('+@nodeKeyList+') group by RPORTMAP.CHILD_TYPE'
      execute(@sql)
    -- Get the count of all Accouts
    -- Need two queries 1 for Folder and 1 for APort
      set @msg = ' Get Count of all Accounts for all RPort under this folder'
      execute absp_Util_Log_HighLevel @msg,@me
      set @sql = 'insert into #DEL_STAT select RPORTMAP.CHILD_TYPE, count(distinct RPORTMAP.CHILD_KEY)  from RPORTMAP  inner join FLDRMAP on FLDRMAP.CHILD_KEY = RPORTMAP.RPORT_KEY and FLDRMAP.CHILD_TYPE = 23 where FLDRMAP.FOLDER_KEY in ('+@nodeKeyList+') group by RPORTMAP.CHILD_TYPE'
      execute(@sql)
      set @msg = ' Get Count of all Accounts for all RPort under any APort that is under this folder'
      execute absp_Util_Log_HighLevel @msg,@me
      set @sql = 'insert into #DEL_STAT select RPORTMAP.CHILD_TYPE, count(distinct RPORTMAP.CHILD_KEY)  from RPORTMAP inner join APORTMAP on APORTMAP.CHILD_KEY = RPORTMAP.RPORT_KEY and APORTMAP.CHILD_TYPE = 23 inner join FLDRMAP on FLDRMAP.CHILD_KEY = APORTMAP.APORT_KEY and FLDRMAP.CHILD_TYPE = 1 where FLDRMAP.FOLDER_KEY in ('+@nodeKeyList+') group by RPORTMAP.CHILD_TYPE'
      execute(@sql)
   end
   else
   begin
      if @nodeType = 1
      begin
         set @sql = 'insert into #DEL_STAT  select '+str(@nodeType)+', count(*) from APRTINFO where APORT_KEY in ('+@nodeKeyList+')'
         execute(@sql)
    -- Get the count of PPort, RPort, RPort Accounts under all APORTs
         set @sql = 'insert into #DEL_STAT select APORTMAP.CHILD_TYPE, count(distinct APORTMAP.CHILD_KEY)  from APORTMAP where APORTMAP.APORT_KEY in ('+@nodeKeyList+') group by APORTMAP.CHILD_TYPE'
         execute(@sql)
    -- Get the count of all Programs
         set @sql = 'insert into #DEL_STAT select RPORTMAP.CHILD_TYPE, count(distinct RPORTMAP.CHILD_KEY)  from RPORTMAP  inner join APORTMAP on APORTMAP.CHILD_KEY = RPORTMAP.RPORT_KEY and APORTMAP.CHILD_TYPE = 3 where APORTMAP.APORT_KEY in ('+@nodeKeyList+') and RPORTMAP.CHILD_TYPE = 7 group by RPORTMAP.CHILD_TYPE'
         execute(@sql)
    -- Get the count of all Accouts
         set @sql = 'insert into #DEL_STAT select RPORTMAP.CHILD_TYPE, count(distinct RPORTMAP.CHILD_KEY)  from RPORTMAP  inner join APORTMAP on APORTMAP.CHILD_KEY = RPORTMAP.RPORT_KEY and APORTMAP.CHILD_TYPE = 23 where APORTMAP.APORT_KEY in ('+@nodeKeyList+') and RPORTMAP.CHILD_TYPE = 27 group by RPORTMAP.CHILD_TYPE'
         execute(@sql)
      end
      else
      begin
         if @nodeType = 2
         begin
            set @sql = 'insert into #DEL_STAT  select '+str(@nodeType)+', count(*) from PPRTINFO where PPORT_KEY in ('+@nodeKeyList+')'
            
            execute(@sql)
             
         end
         else
         begin
            if @nodeType = 3
            begin
               set @sql = 'insert into #DEL_STAT select '+str(@nodeType)+', count(*) from RPRTINFO where RPORT_KEY in ('+@nodeKeyList+')'
               execute(@sql)
    -- Get the count of all Programs
               set @sql = 'insert into #DEL_STAT select RPORTMAP.CHILD_TYPE, count(distinct RPORTMAP.CHILD_KEY)  from RPORTMAP where RPORTMAP.RPORT_KEY in ('+@nodeKeyList+') and RPORTMAP.CHILD_TYPE = 7 group by RPORTMAP.CHILD_TYPE'
               execute(@sql)
            end
            else
            begin
               if @nodeType = 23
               begin
                  set @sql = 'insert into #DEL_STAT select '+str(@nodeType)+', count(*) from RPRTINFO where RPORT_KEY in ('+@nodeKeyList+')'
                  execute(@sql)
    -- Get the count of all Programs
                  set @sql = 'insert into #DEL_STAT select RPORTMAP.CHILD_TYPE, count(distinct RPORTMAP.CHILD_KEY)  from RPORTMAP where RPORTMAP.RPORT_KEY in ('+@nodeKeyList+') and RPORTMAP.CHILD_TYPE = 27 group by RPORTMAP.CHILD_TYPE'
                  execute(@sql)
               end
            end
         end
      end
   end
   if(@isRecursiveCall = 0)
   begin
     select distinct NODE_TYPE as NODE_TYPE,sum(COUNT) as CNT into #DEL_STAT_CNT from #DEL_STAT group by NODE_TYPE
     select   t1.NODE_TYPE AS NODE_TYPE, CNT AS Count from #DEL_STAT_CNT as t1 join NODEDEF as t2 on t1.NODE_TYPE = t2.NODE_TYPE order by NODE_ORDER asc
   end
end







