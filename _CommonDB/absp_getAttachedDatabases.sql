if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GetAttachedDatabases') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GetAttachedDatabases;
end
go

create procedure absp_GetAttachedDatabases @dbType as varchar(3)
as
Begin
	SET NOCOUNT ON;

	--IF EXISTS(SELECT name FROM sysobjects WHERE name = N'TempResultTable' AND xtype='U')
	--	DROP TABLE TempResultTable

	--create TABLE TempResultTable (
	declare @TempResultTable TABLE (
	database_id int,name varchar(120),physical_path varchar(1000),
	size int,growth int,collation_name varchar(100),dbType varchar(3),dbversion varchar(100),build varchar(100))

	declare @dbName as varchar(120),@database_id int,@physical_name  varchar(max),@size int,@growth int,@collation_name  varchar(max)
	DECLARE @objcnt int,@cnt int,@objCntRows int
	DECLARE @objVersion varchar(25),@objBuild varchar(25)
	DECLARE @SQL nvarchar(max)
	DECLARE DBcursor CURSOR FOR
	-- where SDB.owner_sid >1 removed from below query
	select SDB.name, SDB.database_id,SMF.physical_name, SMF.size, SMF.growth,SDB.collation_name from sys.databases SDB  inner join sys.master_files SMF on SDB.database_id = SMF.database_id where SMF.file_id = 1 order by 1 --SDB.owner_sid <=1
	OPEN DBcursor;

	FETCH FROM DBcursor
	INTO @dbName,@database_id,@physical_name,@size,@growth,@collation_name

	WHILE @@FETCH_STATUS = 0
	BEGIN
	   DECLARE @dbContext nvarchar(256)

	   set @dbContext=QuoteName(@dbName)+'.dbo.'+'sp_executeSQL'

	   SET @SQL = 'select @cnt=count(*) from '+QuoteName(@dbName) +'.sys.tables where name = ''RQEVersion'''
	   EXEC @dbContext @SQL,N'@cnt int output',@cnt=@objCnt output;

	   if (@objCnt)>0
			begin
	   		   SET @SQL = 'select @cnt=count(*) from '+QuoteName(@dbName) +'.dbo.RQEVersion where dbType = '+''''+@dbType + ''''
			   EXEC @dbContext @SQL,N'@cnt int output',@cnt=@objCntRows  output;
			   if (@objCntRows>0)
				begin
					SET @SQL= 'select top 1 @Version=RQEVersion,@build=build from RQEVersion where dbType = '+''''+@dbType + ''''
					EXEC @dbContext @SQL,N'@dbTypeInput varchar(3), @Version varchar(25) output,@build varchar(25) output',
					@dbTypeInput=@dbType,@Version=@objVersion output,@build=@objBuild output
					print @SQL
					insert @TempResultTable values (@database_id,@dbName,@physical_name,@size,@growth,@collation_name,@dbType,@objVersion,@objBuild)
				end
			end
	   FETCH FROM Dbcursor
	INTO @dbName,@database_id,@physical_name,@size,@growth,@collation_name

	END
	CLOSE DBcursor;
	DEALLOCATE DBcursor;

	select * from @TempResultTable;
end
