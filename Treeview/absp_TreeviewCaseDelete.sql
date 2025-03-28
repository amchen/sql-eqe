if exists(select 1 from dbo.SYSOBJECTS where ID = object_id(N'dbo.absp_TreeviewCaseDelete') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure dbo.absp_TreeviewCaseDelete
end
 go

create procedure  dbo.absp_TreeviewCaseDelete  @progKey int ,@caseKey int , @isParentDeleted int = 0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure deletes a base case/case.
The logical delete is performed here by setting the STATUS to DELETED. The
real delete is performed as a background process.


Returns:       None.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @progKey ^^  The key of the program which is the parent of the case that is to be removed.
##PD  @caseKey ^^  The key of the case node  which is to be removed.
##PD  @isParentDeleted ^^  Checks whether the parent is deleted or not.

*/
as

BEGIN TRY
   set nocount on
   
   declare @bcaseKey int
   declare @sqlQuery varchar(max)
   declare @longName varchar(255)
   declare @isTreatyNode char(1)
   declare @progType int
   declare @dbName varchar(130)
   declare @irdbName varchar(130)
   declare @cfRefKey int
   
   set @dbName=DB_NAME()
   select @cfRefKey = CF_REF_KEY from commondb.dbo.CFldrInfo where DB_NAME= @dbName;
   
   set @isTreatyNode = 'N'

  -- Check if the case is a Treaty Node
   select   @isTreatyNode = MT_FLAG  from dbo.CASEINFO where CASE_KEY = @caseKey

  -- first we need to see if this is the basecase
   select   @bcaseKey = BCASE_KEY from dbo.PROGINFO where PROG_KEY = @progKey

   -- Change the name to append the key since the user can create a node with the same name as deleted node
   select   @longName = LONGNAME  from dbo.CASEINFO where CASE_KEY = @caseKey
   if(len(ltrim(rtrim(@longName))) = 115)
   begin
      select   @longName = right(ltrim(rtrim(@longName)),110)
   end
   set @longName = ltrim(rtrim(@longName))+'_' + str(@caseKey)
   -- mark the STATUS as DELETED; also set the PROG_KEY to 0 otherwise it will show up in the tree view.
    update CASEINFO set PROG_KEY = 0, STATUS = 'DELETED', LONGNAME = ltrim(rtrim(@longName)) where CASE_KEY = @caseKey
  
   -- insert the INFO record in Results Database
	 exec absp_getDBName  @dbName out, @dbName, 0 -- Enclose within brackets--
	 if RIGHT(rtrim(@dbName),4) != '_IR]'
	 begin
     exec absp_getDBName  @irdbName out, @dbName, 1
     set @sqlQuery = 'set identity_insert ' + @irdbName + '..CASEINFO on;'
     set @sqlQuery = @sqlQuery + 'insert into  ' + @irdbName + '..CASEINFO (CASE_KEY,LONGNAME, STATUS) values (' + dbo.trim(cast(@caseKey as char))+ ',' + dbo.trim(cast(@caseKey as char))+', ''DELETED'' );'
     set @sqlQuery = @sqlQuery + 'set identity_insert  ' + @irdbName + '..CASEINFO off'
     execute (@sqlQuery)
  end
	
   
   update ELTSummary set STATUS = 'DELETED' where (NodeType = 10 or NodeType = 30) and NodeKey = @caseKey

   	--Delete DownloadInfo entries for this node--
	Delete from commondb..DownloadInfo where CaseKey=@caseKey and NodeType=30 and DBRefKey=@cfRefKey
	Delete from commondb..TaskInfo where CaseKey=@caseKey and NodeType=30 and DBRefKey=@cfRefKey

END TRY 
BEGIN CATCH
	declare @ProcName varchar(100)
	select @ProcName=object_name(@@procid)
	exec absp_Util_GetErrorInfo @ProcName
END CATCH