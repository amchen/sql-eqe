if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_PPortResultCounter') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_PPortResultCounter
end
go

create procedure absp_PPortResultCounter @tableToFill varchar(max), @aportList varchar(max), @pportList varchar(max), @exposurekeyList varchar(max)
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure count the no of records of a specific tables based on EXPOSUREKEY or APORT_KEY or PPORT_KEY and writes the infotrmation of that specific tables to a temp table.

Returns: Nothing
              
====================================================================================================

</pre>
</font>
##BD_END
 
##PD  @tableToFill    ^^ This is a temp table.
##PD  @aportList      ^^ This is a list of aport.
##PD  @pportList      ^^ This is a list of pport.
##PD  @exposurekeyList^^ This is a list of exposurekeys.

*/
as	
BEGIN TRY
   declare @MyStrAll varchar(max) 
   declare @TopLvl varchar(max)
   declare @curTable varchar(max)
   declare @sql1 varchar(max)
   declare @sql2 varchar(max)
   
   
   
   		set @MyStrAll=''
   		set @TopLvl ='insert into ' + ltrim(rtrim(@tableToFill))
		set @sql1=' select ''@curTable'' , count(*) from @curTable where Pport_Key @pportList union'
		  declare MyCursor cursor fast_forward for 
			 select TABLENAME from dbo.absp_Util_GetTableList('Aport.Blob')
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
		 
		set @sql1=' select ''@curTable'' , count(*) from @curTable where exposurekey @exposurekeyList union'
		  declare MyCursor cursor fast_forward for 
			 select TABLENAME from dbo.absp_Util_GetTableList('Pport.Blob+Pport.Blob.Agg+Exposure.Blob+Exposure.BlobDone') 
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
	exec absp_Util_log_info @TopLvl, 'absp_PPortResultCounter', 'C:\\_Temp\\dblogs\\Master_DB.log';
	--print @TopLvl
	execute (@TopLvl)		

END TRY 
BEGIN CATCH
	declare @ProcName varchar(100)
	select @ProcName=object_name(@@procid)
	exec absp_Util_GetErrorInfo @ProcName
END CATCH
GO