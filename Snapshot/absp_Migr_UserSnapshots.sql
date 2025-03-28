if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_UserSnapshots') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_UserSnapshots
end
go

create procedure absp_Migr_UserSnapshots  @debug int=0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure will migrate the user snapshots.

Returns:	None

====================================================================================================
</pre>
</font>
##BD_END

*/
as

begin try

	set nocount on
	declare @tableName varchar(120);
	declare @schemaName varchar(255);
	declare @sql varchar(max);
	declare @version varchar(25);
	declare @systemSchema varchar(100);

	--Drop all the existing views for the system tables since those will be referencing the current version from systemdb database--
	declare SnapShotCurs cursor  for select SchemaName from SnapshotInfo where SystemGenerated='N'
	open SnapShotCurs
	fetch SnapShotCurs into @schemaName
	while @@fetch_status=0
	begin
	
 		declare SysViewCurs cursor  for select tableName from systemdb.dbo.DictTbl where SYS_DB in('Y','L') and AllowSnapShot='Y';
		open SysViewCurs
		fetch SysViewCurs into @tableName
		while @@fetch_status=0
		begin
			--Drop if exists--
			if exists (select 1 from sys.views where name=@tableName and  schema_name(schema_id)=@schemaName )
			begin
				set @sql='drop view ' + dbo.trim(@schemaName) + '.' + @tableName;
				if @debug=1 exec absp_MessageEx @sql;
				execute(@sql);
			end

			fetch SysViewCurs into @tableName;
		end;
		close SysViewCurs;
		deallocate SysViewCurs;
		fetch SnapShotCurs into @schemaName;
	end;
	close SnapShotCurs;
	deallocate SnapShotCurs;	
					

	--Get Version Info--
	select top (1) @version=replace(left(rqeversion,5),'.','') from RQEVersion order by RQEVersion desc, Build desc;
	set @systemSchema='RQE'+@version;
	
	--Create a view for all the system tables in each of the user driven snapshot schema. The view will reference table schema specific table
 	declare SnapShotCurs cursor  for select SchemaName from SnapshotInfo where SystemGenerated='N'
	open SnapShotCurs
	fetch SnapShotCurs into @schemaName
	while @@fetch_status=0
	begin
		--Get all system tables
		declare SysVCur cursor  for select tableName from systemdb.dbo.DictTbl where SYS_DB in('Y','L') and AllowSnapShot='Y';
		open SysVCur
		fetch SysVCur into @tableName
		while @@fetch_status=0
		begin
			if exists (select 1 from sys.views where name=@tableName and  schema_name(schema_id)=@schemaName )
			begin
				set @sql='drop view ' + dbo.trim(@schemaName) + '.' + @tableName;
				execute(@sql);
			end

			if exists(select 1 from DictClon where tablename=@tableName)
				set @sql = 'create view ' + dbo.trim(@schemaName) + '.' + @tableName +
					' as select * from systemdb.' + dbo.trim(@SystemSchema) + '.' + @tableName + '_S' +
					' union select * from ' + dbo.trim(@schemaName) + '.' +  @tableName + '_U';
			else
				set @sql = 'create view ' + dbo.trim(@schemaName) + '.' + @tableName + ' as select * from systemdb.' + @SystemSchema+'.' + @tableName;

			if @debug=1 exec absp_MessageEx @sql;
			execute(@sql);
			fetch SysVCur into @tableName;
		end;
		close SysVCur;
		deallocate SysVCur;	
			
		fetch SnapShotCurs into @schemaName;
	end;
	close SnapShotCurs;
	deallocate SnapShotCurs;	

end try

begin catch
	declare @ProcName varchar(100),
			@msg as varchar(1000),
			@module as varchar(100),
			@ErrorSeverity varchar(100),
			@ErrorState int,
			@ErrorMsg varchar(4000);

	select @ProcName = object_name(@@procid);
    	select	@module = isnull(ERROR_PROCEDURE(),@ProcName),
        @msg='"'+ERROR_MESSAGE()+'"'+
        		'  Line: '+cast(ERROR_LINE() as varchar(10))+
				'  No: '+cast(ERROR_NUMBER() as varchar(10))+
				'  Severity: '+cast(ERROR_SEVERITY() as varchar(10))+
        		'  State: '+cast(ERROR_STATE() as varchar(10)),
        @ErrorSeverity=ERROR_SEVERITY(),
        @ErrorState=ERROR_STATE(),
        @ErrorMsg='Exception: Top Level '+@ProcName+'. Occurred in '+@module+'. Error: '+@msg;
	raiserror (
		@ErrorMsg,	-- Message text
		@ErrorSeverity,	-- Severity
		@ErrorState		-- State
	)
	return 99;
end catch
