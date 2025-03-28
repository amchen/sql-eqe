if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_RPortResultCounter') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_RPortResultCounter
end
go
create procedure absp_RPortResultCounter @tableToFill char(20), @aportList varchar(max), @rportList varchar(max), @progList varchar(max), @caseList varchar(max)
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
##PD  @aportList      ^^ This is a list of aport.
##PD  @rportList      ^^ This is a list of rport.
##PD  @progList       ^^ This is a list of prog.
##PD  @caseList       ^^ This is a list of case.

*/as	
BEGIN TRY
   declare @MyStrAll varchar(max) 
   declare @TopLvl nvarchar(max)
   declare @curTable char(120)
   declare @sql1 varchar(4000)
   declare @sql2 varchar(max)
   declare @exposurekeyList varchar(max)
   declare @DBName varchar(100)
   
   set @DBName=substring(db_name(),1,len(db_name())-3) --remove the _IR
   
    set @sql1 = 'select exposurekey from '+@DBName+'.dbo.exposuremap where parentkey '+@rportList+' and ParentType in (7, 27)'
    exec absp_Util_GenInList @exposurekeyList output, @sql1 
      
   		set @MyStrAll=''
   		set @TopLvl ='insert into ' + ltrim(rtrim(@tableToFill))
		set @sql1=' select ''@curTable'' , count(*) from @curTable where Rport_Key @rportList union'
		  declare MyCursor cursor fast_forward for 
			 select TABLENAME from dbo.absp_Util_GetTableList('Rport.Blob')
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
		 
		set @sql1=' select ''@curTable'' , count(*) from @curTable where Aport_Key @aportList union'
		  declare MyCursor cursor fast_forward for 
			 select TABLENAME from dbo.absp_Util_GetTableList('Aport.Blob.Net+Aport.Blob.Rec')
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
		 
		set @sql1=' select ''@curTable'' , count(*) from @curTable where Prog_Key @progList union'
		  declare MyCursor cursor fast_forward for 
			 select TABLENAME from dbo.absp_Util_GetTableList('Program.ProgKey+Treaty.Blob')
		  open MyCursor
		  fetch next from MyCursor into @curTable
		  while @@fetch_status = 0
		  begin
			  set @sql2=replace(@sql1,'@curTable',@curTable)
			  set @sql2=replace(@sql2,'@progList',@progList)
			  set @MyStrAll = @MyStrAll+@sql2
			fetch next from MyCursor into @curTable
		  end
		 close MyCursor
		 deallocate MyCursor
		 
		set @sql1=' select ''@curTable'' , count(*) from @curTable where exposurekey @exposurekeyList union'
		  declare MyCursor cursor fast_forward for 
			 select TABLENAME from dbo.absp_Util_GetTableList('Exposure.Blob+Exposure.BlobDone')
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
	
	set @TopLvl=@TopLvl+left(@MyStrAll,len(@MyStrAll)-5)
	exec absp_Util_log_info @TopLvl, 'absp_RPortResultCounter', 'C:\\_Temp\\dblogs\\Master_DB.log';
	--print @TopLvl
	execute sp_executesql @TopLvl		

END TRY 
BEGIN CATCH
	declare @ProcName varchar(100)
	select @ProcName=object_name(@@procid)
	exec absp_Util_GetErrorInfo @ProcName
END CATCH
GO