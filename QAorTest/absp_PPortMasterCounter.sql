if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_PPortMasterCounter') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_PPortMasterCounter
end
go

create procedure absp_PPortMasterCounter @tableToFill char(20), @aportList varchar(4000), @pportList varchar(4000), @exposurekeyList varchar(4000), @ebeRunIdList varchar(MAX)

/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:
	This procedure count the no of records of a specific tables based on EXPOSUREKEY or APORT_KEY or 
	PPORT_KEY and writes the information of that specific tables to a temp table.
Returns: Nothing
              
====================================================================================================

</pre>
</font>
##BD_END
 
##PD  @tableToFill    ^^ This is a temp table.
##PD  @aportList      ^^ This a list of aport.
##PD  @pportList      ^^ This a list of pport.
##PD  @portIdList     ^^ This a list of port id.

*/
as	
BEGIN TRY
   declare @MyStrAll varchar(max) 
   declare @TopLvl nvarchar(max)
   declare @curTable char(120)
   declare @sql1 varchar(4000)
   declare @sql2 varchar(max)
   
   		set @MyStrAll=''
   		set @TopLvl ='insert into ' + ltrim(rtrim(@tableToFill))
		set @sql1=' select ''@curTable'' , count(*) from @curTable where Pport_Key @pportList union'
		  declare MyCursor cursor fast_forward for 
			 select TABLENAME from dbo.absp_Util_GetTableList('Pport.Report+Policy.Report+Site.Report')
		  open MyCursor
		  fetch next from MyCursor into @curTable
		  while @@fetch_status = 0
		  begin
			  set @sql2=replace(@sql1,'@curTable',@curTable)
			  set @sql2=replace(@sql2,'@pportList',@pportList)
			  set @MyStrAll = @MyStrAll+@sql2
			fetch next from MyCursor into @curTable
		  end
		 close MyCursor
		 deallocate MyCursor	
		 
		set @sql1=' select ''@curTable'' , count(*) from @curTable where exposurekey @exposurekeyList union'
		  declare MyCursor cursor fast_forward for 
			 select TABLENAME from dbo.absp_Util_GetTableList('Reports.Done+Exposure.Report') 
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

	set @MyStrAll = @MyStrAll+' select ''AvailableReport'' , count(*) from AvailableReport where exposurekey '+@exposurekeyList+' union'		 		 	 
	set @MyStrAll = @MyStrAll+' select ''SP_FILES'' , count(*) from SP_FILES where exposurekey '+@exposurekeyList+' union'			 
	
	set @TopLvl=@TopLvl+left(@MyStrAll,len(@MyStrAll)-5)
	exec absp_Util_log_info @TopLvl, 'absp_PPortMasterCounter', 'C:\\_Temp\\dblogs\\Master_DB.log'
	--print @TopLvl
	execute sp_executesql @TopLvl		 

END TRY 
BEGIN CATCH
	declare @ProcName varchar(100)
	select @ProcName=object_name(@@procid)
	exec absp_Util_GetErrorInfo @ProcName
END CATCH
GO