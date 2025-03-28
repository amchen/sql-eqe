if exists(select * from SYSOBJECTS where id = object_id(N'absp_getDistinctCode') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_getDistinctCode
end
 go
create procedure absp_getDistinctCode @nodeKey int ,@targetCurrKey int ,@srcCurrKey int ,@nodeType int ,@targetDB varchar(130) = ''
as
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure finds the number of distinct currency codes used by a specified node which 
are or marked inactive in the target currency schema. If distinct currency codes are
found then it returns two result sets of missing and inactive (existing but inactive) currency
codes in the target currency schema. If no distinct currency codes are found, a NULL will
be returned.

Returns:	1) Two result sets of currency codes 
a. result set of missing codes in the target currency schema (could be empty)
b. result set of inactive codes in the target currency schema (could be empty)
2) or NULL if no distinct currency codes are found. 

====================================================================================================

</pre>
</font>
##BD_END

##PD   	@nodeKey 	^^ The specified node Key.
##PD   	@targetCurrKey	^^ Currency key of the target currency schema.
##PD   	@srcCurrKey	^^ Currency key of the base currency schema.
##PD    @nodeType    ^^ The node type of the specified node
##PD    @targetDB    ^^ The target database name

##RS	code		^^ Missing and inactive Currency codes in target currency schema.
*/
begin

   set nocount on
   
   declare @missingCount int
   declare @sql nvarchar(max)
   declare @inactiveCount int  
    set @missingCount	=0
    set @inactiveCount	=0
   if @targetDB=''
  	set @targetDB= DB_NAME();
  	
    --Enclose within square brackets
   execute absp_getDBName @targetDB out, @targetDB
   
    --Check for Missing and Inactive currency codes
      set @sql = 'select  @missingCount=count(CODE) from EXCHRATE where CURRSK_KEY = ' + str(@srcCurrKey) + ' and
                 not code = any(select  CODE as CODE from ' + dbo.trim(@targetDB) + '..EXCHRATE 
                 where CURRSK_KEY = ' + str(@targetCurrKey) + ' and ACTIVE = ''Y'')'
                 execute sp_executesql @sql,N'@missingCount int output',@missingCount output
		--print '@missingCount: '+str(@missingCount) 
		
      set @sql = 'select  @inactiveCount=count(CODE) from EXCHRATE  where CURRSK_KEY = ' + str(@srcCurrKey) + ' and
                 code = any(select  CODE as CODE from ' + dbo.trim(@targetDB) + '..EXCHRATE 
                 where CURRSK_KEY = ' + str(@targetCurrKey) + ' and ACTIVE = ''N'')'
				execute sp_executesql @sql,N'@inactiveCount int output',@inactiveCount output	
		--print '@inactiveCount: '+str(@inactiveCount)
		
	if (@missingCount+@inactiveCount >0)
	   begin
		 --Retrive the missing codes.
		  set @sql = 'select  CODE as CODE from EXCHRATE where CURRSK_KEY = ' + str(@srcCurrKey) + ' and
					 not code = any(select  CODE as CODE from ' + dbo.trim(@targetDB) + '..EXCHRATE 
					 where CURRSK_KEY = ' + str(@targetCurrKey) + ' and ACTIVE = ''Y'')'
		  execute(@sql)

		-- Retrive the inactive codes.
		  set @sql = 'select  CODE as CODE from EXCHRATE  where CURRSK_KEY = ' + str(@srcCurrKey) + ' and
					 code = any(select  CODE as CODE from ' + dbo.trim(@targetDB) + '..EXCHRATE 
					 where CURRSK_KEY = ' + str(@targetCurrKey) + ' and ACTIVE = ''N'')'
		  execute(@sql)
	   end
	   else
	   begin
		  return null
	   end
end




