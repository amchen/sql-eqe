if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_MCF_Load') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_MCF_Load
end

go
create procedure absp_Util_MCF_Load
@dbName varchar(128) = 'CF1',
@xmlPath varchar(254) ='C:\Projects\Features\Data_files\CD-Db\EDM\MISC\PROC2LOAD.xml'
/*
##BD_BEGIN
font size =3
pre style=font-family Lucida Console;
====================================================================================================
DB Version    MSSQL
Purpose

	This procedure loads stored procedures and scripts to create tables/views into related databases
	for multiple currency folder database environment
	(only works in multiple-databases environment)

Returns	None

====================================================================================================
pre
font
##BD_END
*/

AS
begin
	set nocount on
	declare @vFileName varchar(200)
	declare @vSQLStmt  varchar(4000)
	declare @userPwdStr varchar(254)
	declare @procFilePath varchar(254)
	declare @serverName varchar(254)
	declare @userName varchar(80)
	declare @passwrd varchar(80)
	declare @execCmd varchar(255)
	declare @fileContents varchar(MAX)

	declare @pri int
	declare @ir int
	declare @sys int
	declare @com int
	declare @Pointer int
	declare @y int
	declare @x int


	-- read the content of the xml file

	create table #tempXML(PK int not null identity(1,1), line varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS)

	set @execCmd = 'type ' + @xmlPath
	set @fileContents = ''

	insert into #tempXML exec master.dbo.xp_cmdshell @execCmd
	delete from #tempXML where line is null
	select @y = count(*) from #tempXML

	set @x = 0
	while @x <> @y
	begin
	    set @x = @x + 1
	    select @fileContents = @fileContents + isnull(line, '') from #tempXML WHERE PK = @x
	end

	--select @fileContents as fileContents
	drop table #tempXML

	-- read the parameter: procure file path, server, username, password ... from the contentxml file

	if object_id('tempdb..##SQLParams') is null
	begin
		create table ##SQLParams ( procFilePath varchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS, serverName varchar(254) COLLATE SQL_Latin1_General_CP1_CI_AS, userName varchar(80) COLLATE SQL_Latin1_General_CP1_CI_AS, passwrd varchar(80) COLLATE SQL_Latin1_General_CP1_CI_AS)
	end
	truncate table ##SQLParams

	execute sp_xml_preparedocument @Pointer OUTPUT,@fileContents

	insert into ##SQLParams (procFilePath, serverName, userName, passwrd)
	select procedureFilePath, serverName, userName, password
	from
	      OPENXML (@Pointer,'/load/params')
	      with
	      (
	      	procedureFilePath varchar(254),
	      	serverName varchar(254),
	      	userName varchar(80),
	      	password varchar(80)
	      )

    	execute sp_xml_removedocument @Pointer
    	select top 1 @procFilePath = procFilePath, @serverName = serverName, @userName = userName, @passwrd = passwrd from ##SQLParams

    	drop table ##SQLParams

	-- use trusted connection or SQL uid and pwd?
	if len(@userName) = 0 or len(@passwrd) = 0
		set @userPwdStr = ' -E '
	else
		set @userPwdStr = ' -U ' + ltrim(rtrim(@userName)) + ' -P ' + ltrim(rtrim(@passwrd))

	-- read stored procedures/ table script entries from the content of the xml file

	if object_id('tempdb..##SQLFiles') is null
	begin
		create table ##SQLFiles ( SQLFileName varchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS, PRI int, IR int, SYS int, COM int)
	end
	truncate table ##SQLFiles

	execute sp_xml_preparedocument @Pointer OUTPUT,@fileContents
	      INSERT INTO ##SQLFiles (SQLFileName, PRI, IR, SYS, COM)
	      SELECT SQLFileName, PRI, IR, SYS, COM
	      FROM
	      OPENXML (@Pointer,'/load/file')
	      WITH
	      (
		SQLFileName varchar(254),
		PRI int,
		IR int,
		SYS int,
		COM int
	      )
    	execute sp_xml_removedocument @Pointer

	-- get the entries for loading stored procedures or scripts to create tables and views here
	-- PRI = 1: loading sql into the primary database, IR =1:  loading sql into the IR database
	-- SYS = 1: loading sql into the system database,  COM =1: loading sql into the common database

	declare cFiles cursor local for
	    select distinct [SQLFileName], [PRI], [IR], [SYS], [COM]
	    from ##SQLFiles
	    where [SQLFileName] is not null and
	          [SQLFileName] != 'NULL'
	    order by [SQLFileName]

	open cFiles
	fetch next from cFiles into @vFileName, @pri, @ir, @sys, @com
	while @@fetch_status = 0
	begin

	    if(@pri = 1)
	    begin
		set @vSQLStmt = 'master.dbo.xp_cmdshell ''osql -S ' + ltrim(rtrim(@serverName)) +
				 rtrim(@userPwdStr) +
				' -d ' + ltrim(rtrim(@dbName)) + ' -i "' +
					ltrim(rtrim(@procFilePath)) + ltrim(rtrim(@vFileName)) + '"'''
		print @vSQLStmt
		execute (@vSQLStmt)
	    end

	    if(@ir = 1)
	    begin
	    	set @vSQLStmt = 'master.dbo.xp_cmdshell ''osql -S ' + ltrim(rtrim(@serverName)) +
	    			 rtrim(@userPwdStr) +
	    			' -d ' + ltrim(rtrim(@dbName)) + '_IR '+ ' -i "' +
	    				ltrim(rtrim(@procFilePath)) + ltrim(rtrim(@vFileName)) + '"'''

	    	print @vSQLStmt
	    	execute (@vSQLStmt)
	    end

	    if(@sys = 1)
	    begin
	    	set @vSQLStmt = 'master.dbo.xp_cmdshell ''osql -S ' + ltrim(rtrim(@serverName)) +
	    			 rtrim(@userPwdStr) +
	    			' -d systemdb -i "' +
	    				ltrim(rtrim(@procFilePath)) + ltrim(rtrim(@vFileName)) + '"'''
	    	print @vSQLStmt
	    	execute (@vSQLStmt)
	    end

	    if(@com = 1)
	    begin
	       	set @vSQLStmt = 'master.dbo.xp_cmdshell ''osql -S ' + ltrim(rtrim(@serverName)) +
	       			 rtrim(@userPwdStr) +
	       			' -d commondb -i "' +
	       				ltrim(rtrim(@procFilePath)) + ltrim(rtrim(@vFileName)) + '"'''

	       	print @vSQLStmt
	       	execute (@vSQLStmt)
	    end

	    fetch next from cFiles into @vFileName, @pri, @ir, @sys, @com
	end

	close cFiles
	deallocate cFiles

	drop table ##SQLFiles

end