if exists(select * from SYSOBJECTS where ID = object_id(N'absp_generateLockId') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_generateLockId
end
go

create procedure absp_generateLockId @tempName varchar(120), @lockTableName varchar(120), @parentKey int,@parentType int,@extraKey int,@lockIdStr varchar(max),@debugFlag int = 0 
as 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure generates a lockid for the given node based on the child key 
and child type in a particular fashion as following.

a)  when node is a site or policy LockID = lockIdStr=childType:extraKey:childKey
b)  when node is other than site or policy LockID = lockIdStr = childType:childKey
c)  when node is a currency node LockID = lockIdStr=nodeType:curRefKey:nodeKey

Returns:       Nothing

=================================================================================
</pre>
</font>
##BD_END

##PD  parentKey  ^^ The key for the parent node.
##PD  parentType ^^ The type of the parent node.
##PD  extraKey   ^^ An unused parameter.
##PD  lockIdStr  ^^ The string with which the lockid will start.
##PD  debugFlag  ^^ A flag value used for debugging(default set to 0).
*/
begin try
 
   set nocount on
   
   declare @me varchar(max)
   declare @debug int -- to handle sql type work
  -- put other variables here
   declare @msg varchar(max)
   declare @sql varchar(max)
   
  -- initialize standard items
   set @me = 'absp_generateLockId: ' -- set to my name Procedure Name
   set @debug = @debugFlag -- initialize
   set @msg = @me+'starting'

   -- build cursor query
   set @sql = 
	' with cte (CHILD_KEY, CHILD_TYPE, EXTRA_C_KEY ) as ' +
	        ' ( ' +
			' select Distinct CHILD_KEY, CHILD_TYPE, EXTRA_C_KEY ' +
			' from ' + @tempName +  
			' where PARENT_KEY = ' + ltrim(rtrim(str(@ParentKey))) + ' And PARENT_TYPE = ' + ltrim(rtrim(str(@parentType))) +
		' ) ' +
	' select  distinct cte.CHILD_KEY, cte.CHILD_TYPE , cte.EXTRA_C_KEY ' +
	' from cte , ' + ltrim(rtrim(@tempName)) + ' T Where T.PARENT_KEY = ' + ltrim(rtrim(str(@parentKey ))) + 
    ' order by child_type ' +
    ' option (maxrecursion 32767)'

    -- declare curs1 cursor
    set @sql = 'declare @childKey int; declare @childType int; declare @extraKey2 int; declare @lockId varchar(max); ' +
				'declare curs1 cursor local for ' + @sql + '; open curs1; '
    -- build the fetch loop
    set @sql = @sql +  
    'fetch next from curs1 into @childKey, @childType, @extraKey2 ' +
    ' while @@fetch_status = 0' +
    ' begin '+ 
    	' if (len(@lockId) > 0 ) ' +
    	' begin ' +
    		' insert into ' + rtrim(ltrim(@lockTableName)) + ' values (''' + ltrim(rtrim(@lockIdStr)) +'''); ' +	
			' set @lockId = ''' + ltrim(rtrim(@lockIdStr)) +'''; ' +
		' end ' +
    	' select @lockId = lockId  from ' + rtrim(ltrim(@lockTableName)) + ' where LOCKID =  ''' + ltrim(rtrim(@lockIdStr)) + '''; '  +
		' if(@childType = 4 OR @childType = 8 OR @childType = 9) ' +
		' begin ' +
			' set @lockId = @lockId + ''_'' + ltrim(rtrim(str(@childType))) + '':''+ ltrim(rtrim(str(@extraKey2))) +'':''+ ltrim(rtrim(str(@childKey))); ' +
		' end ' +
		' else ' +
		' begin ' +
			' set @lockId = @lockId +''_''+ ltrim(rtrim(str(@childType)))+'':''+ ltrim(rtrim(str(@childKey))); ' +
		' end ' +
	    ' update ' + rtrim(ltrim(@lockTableName)) + ' set LOCKID = @lockId where lockId = ''' + ltrim(rtrim(@lockIdStr)) + '''; ' +
		' execute absp_generateLockId ''' + ltrim(rtrim(@tempName)) + ''', ''' + 
		 ltrim(rtrim(@lockTableName)) + ''', @childKey, @childType, @extraKey2, @lockId; ' +
		' fetch next from curs1 into @childKey, @childType, @extraKey2 ' +
    ' end ' +	
    ' close curs1 ' +
    ' deallocate curs1 '
    
    --print @sql
    execute(@sql)
 
end try

begin catch
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
	
   set @sql = 'if exists ( select * from tempdb..sysobjects ' +
   	'where name = ''' + @lockTableName + ''' ) ' + 
   	'drop table ' + @lockTableName + ';' +
	'if exists ( select * from tempdb..sysobjects ' +
	'where name = ''' + @tempName + ''' ) ' + 
	'drop table ' + @tempName
	--print 'aborted cleanup: ' + @sql
	execute(@sql)	
	
end catch  
