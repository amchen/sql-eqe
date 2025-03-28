if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_GetResultsInvalidationLockInfo') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_GetResultsInvalidationLockInfo
end

go

create  procedure absp_GetResultsInvalidationLockInfo 
@tempPath varchar(max) = ''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure finds out all portfolios that are marked for invalidation generates lock information 
for those invalidating portfolios (Temporary Table #LOCKINFO is assumed previously created)

Returns:	nothing

====================================================================================================
</pre>
</font>
##BD_END
##PD  @tempPath ^^	log file path 
*/
AS
begin

  set nocount on
   declare @execStr varchar(max)  
   declare @curs1 cursor
   declare @curs1_NodeKey int
   declare @curs1_NodeType int
   declare @curs1_LongName varchar(120)
   
   declare @TableVar table (NODE_KEY INT, NODE_TYPE INT, LONGNAME varchar(120) COLLATE SQL_Latin1_General_CP1_CI_AS)
	insert into @TableVar exec absp_GetInvalidatingNodesList
   
   IF OBJECT_ID('tempdb..#LOCKINFO','u') IS NULL
   begin
	   exec absp_Util_LogIt ' inside absp_GetResultsInvalidationLockInfo: LOCKINFO doesnt exist... It will be created!' ,1 ,'absp_GetResultsInvalidationLockInfo' , @tempPath
	   --print ' inside absp_GetResultsInvalidationLockInfo: LOCKINFO doesnt exist... It will be created!'
	   create table #LOCKINFO
	   (
			 KEY1 	  int,
			 KEY2 	  int,
			 KEY3 	  int,
			 NODETYPE int    
	   )
   end

   --print '     ' 
   --print '====================================' 
   --print 'absp_GetResultsInvalidationLockInfo: starting'
   exec absp_Util_LogIt '     '								   ,1 ,'absp_GetResultsInvalidationLockInfo' , @tempPath
   exec absp_Util_LogIt '====================================' ,1 ,'absp_GetResultsInvalidationLockInfo' , @tempPath
   exec absp_Util_LogIt 'absp_GetResultsInvalidationLockInfo: starting' ,1 ,'absp_GetResultsInvalidationLockInfo' , @tempPath

   set @curs1 = cursor fast_forward for select NODE_KEY, NODE_TYPE, LONGNAME from @TableVar
   open @curs1
   fetch next from @curs1 into @curs1_NodeKey, @curs1_NodeType, @curs1_LongName
   while @@fetch_status = 0
   begin
         
         set @execStr = 'insert into #LOCKINFO values( ' + rtrim(ltrim(str(@curs1_NodeKey))) + ',0,0,' + rtrim(ltrim(str(@curs1_NodeType))) + ')'
         exec absp_Util_LogIt @execStr ,1 ,'absp_GetResultsInvalidationLockInfo' , @tempPath
   		 execute(@execStr)
         
         fetch next from @curs1 into @curs1_NodeKey, @curs1_NodeType, @curs1_LongName
   end
   close @curs1
   deallocate @curs1

   --print 'absp_GetResultsInvalidationLockInfo: ending'
   --print '     '
   exec absp_Util_LogIt 'absp_GetResultsInvalidationLockInfo: ending' ,1 ,'absp_GetResultsInvalidationLockInfo' , @tempPath
   exec absp_Util_LogIt '===========================================' ,1 ,'absp_GetResultsInvalidationLockInfo' , @tempPath
   exec absp_Util_LogIt '     ' ,1 ,'absp_GetResultsInvalidationLockInfo' , @tempPath
end