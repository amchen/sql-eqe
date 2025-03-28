if exists ( select 1 from sysobjects where name = 'absp_RPortMasterCounter' and type = 'P' )
begin
	drop procedure absp_RPortMasterCounter
end
Go
create procedure absp_RPortMasterCounter @tableToFill char(20), @aportList  varchar(4000), @rportList  varchar(4000), @progList  varchar(4000), @caseList  varchar(4000), @ebeRunIdList varchar(MAX), @nodeType int
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure count the no of records of a specific tables based on APORT_KEY or RPORT_KEY or PROG_KEY or CASE_KEY  and writes the infotrmation of that specific tables to a temp table.

Returns: Nothing

====================================================================================================

</pre>
</font>
##BD_END

##PD  @tableToFill    ^^ This is a temp table.
##PD  @aportList      ^^ This a list of aport.
##PD  @rportList      ^^ This a list of rport.
##PD  @progList       ^^ This a list of prog.
##PD  @caseList       ^^ This a list of case.

*/
as
BEGIN TRY
   declare @MyStrAll varchar(max) 
   declare @TopLvl nvarchar(max)
   declare @curTable char(120)
   declare @sql1 varchar(4000)
   declare @sql2 varchar(max)
   declare @exposurekeyList varchar(1000)
   
   set @sql1 = 'select exposurekey from exposuremap where ParentKey'+@rportList+' and ParentType=27'
    exec absp_Util_GenInList @exposurekeyList output, @sql1
    
   		set @MyStrAll=''
   		set @TopLvl ='insert into ' + ltrim(rtrim(@tableToFill))
		set @sql1=' select ''@curTable'' , count(*) from @curTable where RPORT_KEY @rportList union'
		  declare MyCursor cursor fast_forward for 
			 select TABLENAME from dbo.absp_Util_GetTableList('Rport.Report+Rport.Done')
		  open MyCursor
		  fetch next from MyCursor into @curTable
		  while @@fetch_status = 0
		  begin
			  set @sql2=replace(@sql1,'@curTable',@curTable)
			  set @sql2=replace(@sql2,'@rportList',@rportList)
			  set @MyStrAll = @MyStrAll+@sql2
			fetch next from MyCursor into @curTable
		  end
		 close MyCursor
		 deallocate MyCursor	
		 
		set @sql1=' select ''@curTable'' , count(*) from @curTable where CASE_KEY @caseList union'
		  declare MyCursor cursor fast_forward for 
			 select TABLENAME from dbo.absp_Util_GetTableList('Case.Report'); 
		  open MyCursor
		  fetch next from MyCursor into @curTable
		  while @@fetch_status = 0
		  begin
			  set @sql2=replace(@sql1,'@curTable',@curTable)
			  set @sql2=replace(@sql2,'@caseList',@caseList)
			  set @MyStrAll = @MyStrAll+@sql2
			fetch next from MyCursor into @curTable
		  end
		 close MyCursor
		 deallocate MyCursor	

		set @sql1=' select ''@curTable'' , count(*) from @curTable where exposurekey @exposurekeyList union'
		  declare MyCursor cursor fast_forward for 
			 select TABLENAME from dbo.absp_Util_GetTableList('Exposure.Report') 
		  open MyCursor
		  fetch next from MyCursor into @curTable
		  while @@fetch_status = 0
		  begin
			  set @sql2=replace(@sql1,'@curTable',@curTable)
			  set @sql2=replace(@sql2,'@exposurekeyList',@exposurekeyList)
			  set @MyStrAll = @MyStrAll+@sql2
			fetch next from MyCursor into @curTable
		  end
		 close MyCursor
		 deallocate MyCursor
		 
		set @sql1=' select ''@curTable'' , count(*) from @curTable where EBERUNID @ebeRunIdList union'
		  declare MyCursor cursor fast_forward for 
			 select TABLENAME from dbo.absp_Util_GetTableList('ELT.Report') 
		  open MyCursor
		  fetch next from MyCursor into @curTable
		  while @@fetch_status = 0
		  begin
			  set @sql2=replace(@sql1,'@curTable',@curTable)
			  set @sql2=replace(@sql2,'@ebeRunIdList',@ebeRunIdList)
			  set @MyStrAll = @MyStrAll+@sql2
			fetch next from MyCursor into @curTable
		  end
		 close MyCursor
		 deallocate MyCursor	

	set @MyStrAll = @MyStrAll+' select ''SP_FILES'' , count(*) from SP_FILES where exposurekey '+@exposurekeyList+' union'			 
	set @MyStrAll = @MyStrAll+' select ''ExposureReportInfo'' , count(*) from ExposureReportInfo where exposurekey '+@exposurekeyList+' and Status=''Active'' union'			 
	
	set @TopLvl=@TopLvl+left(@MyStrAll,len(@MyStrAll)-5)
	exec absp_Util_log_info @TopLvl, 'absp_RPortMasterCounter', 'C:\\_Temp\\dblogs\\Master_DB.log'
	--print @TopLvl
	execute sp_executesql @TopLvl		 

END TRY 
BEGIN CATCH
	declare @ProcName varchar(100)
	select @ProcName=object_name(@@procid)
	exec absp_Util_GetErrorInfo @ProcName
END CATCH