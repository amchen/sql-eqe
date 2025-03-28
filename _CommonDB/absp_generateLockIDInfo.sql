if exists(select * from SYSOBJECTS where ID = object_id(N'absp_generateLockIDInfo') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_generateLockIDInfo
end
go

create procedure absp_generateLockIDInfo @lockSessionKey int, @parentKey int,@parentType int,@extraKey int,@lockIdStr varchar(max),@debugFlag int = 0 
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

##PD  lockSessionKey ^^ The lock session key for the parent node.
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
   set @me = 'absp_generateLockIDInfo: ' -- set to my name Procedure Name
   set @debug = @debugFlag -- initialize
   set @msg = @me+'starting'

   -- build cursor query
   set @sql = 
	' with cte (childKey, childType, childExposureKey ) as ' +
	        ' ( ' +
			' select distinct childKey, childType, childExposureKey ' +
			' from [commondb].dbo.LockTreeMap ' +  
			' where parentKey = ' + ltrim(rtrim(str(@ParentKey))) + ' and parentType = ' + ltrim(rtrim(str(@parentType))) + ' and LockSessionKey = ' + ltrim(rtrim(str(@lockSessionKey))) +
		' ) ' +
	' select  distinct cte.childKey, cte.childType , cte.childExposureKey ' +
	' from cte , [commondb].dbo.LockTreeMap T Where T.parentKey = ' + ltrim(rtrim(str(@parentKey ))) + ' and LockSessionKey = ' + ltrim(rtrim(str(@lockSessionKey))) +
    ' order by childType ' +
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
    		' insert into [commondb].dbo.LockIDInfo values (' + ltrim(rtrim(str(@lockSessionKey)))  + ','''+ ltrim(rtrim(@lockIdStr)) + '''); ' +
			' set @lockId = ''' + ltrim(rtrim(@lockIdStr)) +'''; ' +
		' end ' +
    	' select @lockId = lockId  from [commondb].dbo.LockIDInfo  where LOCKID =  ''' + ltrim(rtrim(@lockIdStr)) + ''' and LockSessionKey = ' + ltrim(rtrim(str(@lockSessionKey))) + '; '  +
		' if(@childType = 4 OR @childType = 8 OR @childType = 9) ' +
		' begin ' +
			' set @lockId = @lockId + ''_'' + ltrim(rtrim(str(@childType))) + '':''+ ltrim(rtrim(str(@extraKey2))) +'':''+ ltrim(rtrim(str(@childKey))); ' +
		' end ' +
		' else ' +
		' begin ' +
			' set @lockId = @lockId +''_''+ ltrim(rtrim(str(@childType)))+'':''+ ltrim(rtrim(str(@childKey))); ' +
		' end ' +
	    ' update [commondb].dbo.LockIDInfo set LOCKID = @lockId where lockId = ''' + ltrim(rtrim(@lockIdStr)) + ''' and LockSessionKey = ' + ltrim(rtrim(str(@lockSessionKey))) + '; ' +
		' execute absp_generateLockIDInfo ' + ltrim(rtrim(str(@lockSessionKey))) + ', @childKey, @childType, @extraKey2, @lockId; ' +
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
  delete from [commondb].dbo.LockTreeMap where LockSessionKey = @LockSessionKey;
  delete from [commondb].dbo.LockIDInfo where LockSessionKey = @LockSessionKey;
end catch  
