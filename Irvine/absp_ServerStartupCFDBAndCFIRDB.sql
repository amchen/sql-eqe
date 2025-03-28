if exists(select * from SYSOBJECTS where ID = object_id(N'absp_ServerStartupCFDBAndCFIRDB') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_ServerStartupCFDBAndCFIRDB
end
go

create procedure absp_ServerStartupCFDBAndCFIRDB
	@startupLevel int,
	@groupId int,
	@logFileName char(255) = '',
	@blobValidateLevel int = 0,
	@cleanupFinalResults int = 1,
	@pofCleanupLevel int = 0,
	@userName varchar(100) = '', 
	@password varchar(100) = '',
	@irDbName varchar(125) = ''
	
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:
              This procedure is basically a wrapper procedure to run some start up procedures on a newly attached primary and IR database

Returns:       Nothing.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @startupLevel ^^ Unused parameter
##PD  @groupId ^^ DBTASKS group Id
##PD  @logFileName ^^  The log file name 
##PD  @blobValidateLevel ^^  The blob validate level
##PD  @cleanupFinalResults ^^  A flag to indicate whether to cleanup Final results 
##PD  @pofCleanupLevel ^^  A flag to indicate whether to cleanup orphan portfolios
##PD  @userName ^^ The userName - in case of SQL authentication
##PD  @password ^^ The password - in case of SQL authentication
##PD  @irDbName ^^ IR database name
*/

begin
	set nocount on

	declare @qry as nvarchar(max)
	
	set @qry = 'exec absp_ServerStartupCFDB ' + ltrim(rtrim(str(@startupLevel))) + ',' + ltrim(rtrim(str(@groupId))) + ',''' + ltrim(rtrim(@logFileName)) + ''',' + ltrim(rtrim(str(@blobValidateLevel))) + ',' + ltrim(rtrim(str(@cleanupFinalResults))) + ',' + ltrim(rtrim(str(@pofCleanupLevel))) + ',''' + ltrim(rtrim(@userName)) + ''',''' + ltrim(rtrim(@password)) + ''';';
	print @qry
	exec sp_executesql @qry;
	
	set @qry = 'exec [@dbname].dbo.absp_ServerStartupCFIRDB';
	set @qry = replace(@qry, '@dbname', @irDbName);
	print @qry
	exec sp_executesql @qry;				
						
end