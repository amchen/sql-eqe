if exists(select * from SYSOBJECTS where ID = object_id(N'absp_BackupDatabase') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_BackupDatabase
end
go

create procedure absp_BackupDatabase
as
/* 
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose: 

The procedure takes the backup of the WCE database.

Returns:       None.

=================================================================================
</pre> 
</font> 
##BD_END 

*/
begin

   set nocount on
   
	declare @sql varchar(4000)
	declare @dbName varchar(512)
	-- Create a logical backup device for data backups of wce database.
	declare @retVal int
	exec @retVal = absp_Util_CreateFolder 'c:\wce database backup'
	
	select @dbName = ltrim(rtrim(db_name()))
	set @sql = 'BACKUP DATABASE '+ @dbName +' to disk = ''c:\wce database backup\' + @dbName + '.mdf'''
	execute (@sql)
	set @sql = 'BACKUP LOG '+ @dbName +' to disk = ''c:\wce database backup\' + @dbName + '.ldf'''
	execute (@sql)
end
