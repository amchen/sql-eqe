if exists ( select 1 from sysobjects where name = 'absp_APortMasterCounter' and type = 'P' )
begin
	drop procedure absp_APortMasterCounter
end
Go

create procedure absp_APortMasterCounter  @tableToFill char(20), @aportList varchar(MAX), @ebeRunIdList varchar(MAX)
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       This procedure count the no of records of a specific tables based on APORT_KEY
			   writes the infotrmation of that specific tables to a temp table.

Returns:       Nothing

====================================================================================================

</pre>
</font>
##BD_END

##PD  @tableToFill    ^^ This is a temp table.
##PD  @aportList      ^^ This is a list of aport.

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
		set @sql1=' select ''@curTable'' , count(*) from @curTable where Aport_Key @aportList union'
		  declare MyCursor cursor fast_forward for 
			 select TABLENAME from dbo.absp_Util_GetTableList('Aport.Report') 
		  open MyCursor
		  fetch next from MyCursor into @curTable
		  while @@fetch_status = 0
		  begin
			  set @sql2=replace(@sql1,'@curTable',@curTable)
			  set @sql2=replace(@sql2,'@aportList',@aportList)
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
		 
	set @TopLvl=@TopLvl+left(@MyStrAll,len(@MyStrAll)-5)
	exec absp_Util_log_info @TopLvl, 'absp_APortMasterCounter', 'C:\\_Temp\\dblogs\\Master_DB.log'
	--print @TopLvl
	execute sp_executesql @TopLvl		 

END TRY 
BEGIN CATCH
	declare @ProcName varchar(100)
	select @ProcName=object_name(@@procid)
	exec absp_Util_GetErrorInfo @ProcName
END CATCH
GO