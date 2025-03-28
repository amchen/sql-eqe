if exists(select * from SYSOBJECTS where ID= object_id(N'absp_TableCountAllToFile_ForAllCF') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_TableCountAllToFile_ForAllCF
end

go

create procedure absp_TableCountAllToFile_ForAllCF @outputPath varchar(1000) , 
												   @userName varchar(1000)='' ,
												   @password varchar(1000)=''
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure gets the rowcount of all non-client-side tables for each currency folder and saves 
        the information under the given folder.

Returns: Nothing
              
====================================================================================================

</pre>
</font>
##BD_END
 
##PD  outputPath    ^^ The path where the information is to be saved.


*/
as
begin
   set nocount on
	
	declare @cfPath varchar(1000)
	declare @dbname varchar(120)
	declare @msg varchar(400)
	declare @retVal int
	declare @fileName varchar(100)

	set @fileName='TableCount.txt'

	--Delete the root folder if it exists
	exec @retVal = absp_Util_DeleteFolder @outputPath, 1 
	if @retVal<>0 
	begin
		set @msg = 'Unable to delete folder ' + @outputPath
		exec absp_MessageEx @msg
		return
	end

	--create root folder
	exec @retVal = absp_Util_CreateFolder @outputPath

	if @retVal<>0 
	begin
		set @msg = 'Unable to create folder ' + @outputPath
		exec absp_MessageEx @msg
		return
	end
	--Get the currency folders
	declare cf cursor for select DB_NAME from commondb..CFLDRINFO
    open cf
	fetch cf into @dbname
	while @@fetch_status=0
	begin
		 --create  folder
		 set @cfPath = @outputPath + '\\' + dbo.trim(@dbname)
		 exec absp_Util_CreateFolder @cfPath
		 
         set @cfPath= @cfPath + '\\' + @fileName

		 --Enclose dbName within square brackets--
		 execute absp_getDBName @dbname out, @dbname

		 exec absp_TableCountAllToFile @dbname, @cfPath, @userName, @password	 
		
		 fetch cf into @dbname
	end
	close cf
	deallocate cf 

end


  