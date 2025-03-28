if exists(select * from SYSOBJECTS where ID = object_id(N'absp_007787_MigrateYLTPortData') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_007787_MigrateYLTPortData;
end
go

create procedure  absp_007787_MigrateYLTPortData
as

begin
	set nocount on;

	--7787: Migration needed for YLTPortData table in the RDB

	declare @tableName varchar(300);
	declare @tmpTableName varchar(300);
	declare @rdbInfoKey int;
	declare @yltId int;
	declare @sql varchar(max);
	declare @msg varchar(max);
	declare @migrationNeeded int;
	
	begin try
	
		--Check if migration has already taken place for  YLTPortData tables
		set @migrationNeeded = 0	
		declare cursCh cursor for select rdbInfoKey,tableName from YltSummary;
		open cursCh;
		fetch cursCh into @rdbInfoKey, @tableName;
		while @@FETCH_STATUS =0
		begin
			set @tmpTableName = 'YLTPortData_' + dbo.trim(CAST(@rdbInfoKey as varchar(30)));
			if @tmpTableName <> @tablename
			begin
				set @migrationNeeded = 1
				break
			end
			fetch cursCh into @rdbInfoKey, @tableName;
		end
		close cursCh;
		deallocate cursCh;
		
		if @migrationNeeded = 0	return;
			
		--Rename all YLTPortData_xx to tmpYLTPortData_xx
		declare c1 cursor for
			select name from sys.tables
				where name like 'YLTPortData%'
				  and name <> 'YLTPortData';
		open c1;
		fetch c1 into @tableName;
		while @@FETCH_STATUS =0
		begin
			set @msg = 'Rename ' + @tableName+ ' to ' + @tmpTableName;
			print @msg;
			set @tmpTableName = 'TMP' + @tableName;
			if not exists(select 1 from sys.tables where name=@tmpTableName)
				exec sp_rename @tableName,@tmpTableName;
			fetch c1 into @tableName;
		end;
		close c1;
		deallocate c1;

		--For each YltSummary.RdbInfoKey create a table in the format YLTPortData_<RdbInfoKey>
		declare c2 cursor for select distinct RdbInfoKey from YltSummary
		open c2;
		fetch c2 into @rdbInfoKey;
		while @@FETCH_STATUS =0
		begin
			set @tmpTableName = 'YLTPortData_' + dbo.trim(cast(@rdbInfoKey as varchar(30)));
			set @msg = 'Create table ' + @tmpTableName;
			print @msg;

			exec systemdb..absp_Util_CreateTableScript @sql out,'YLTPortData',@tmpTableName,'',1;
			if exists(select 1 from sys.objects where name=@tmpTableName and type='U')
				exec ('drop table ' + @tmpTableName);
			exec (@sql);
			fetch c2 into @rdbInfoKey;
		end;
		close c2;
		deallocate c2;

		--For each YLTSummary.YLTID
		declare c3 cursor for select YLTID,RdbInfoKey from YLTSummary
		open c3;
		fetch c3 into @yltId, @rdbInfoKey;
		while @@FETCH_STATUS =0
		begin
			--copy everything from tmpYLTPortData_<YLTID> to YLTPortData_<RdbInfoKey> using the corresponding YLTSummary.RdbInfoKey (structure is the same)
			set @tableName='YltPortData_' +  dbo.trim(cast(@rdbInfoKey as varchar(30)));
			set @tmpTableName = 'TMPYLTPortData_' + dbo.trim(cast(@yltId as varchar(30)));
			
			set @msg = 'Copy from ' + @tmpTableName +' to ' + @tableName;
			print @msg
			
			set @sql='insert into ' + @tableName + ' select * from ' + @tmpTableName ;
			print @sql
			exec (@sql);

			--drop tmpYLTPortData_<YLTID>
			exec ('drop table ' + @tmpTableName);

			--update YLTSummary.TableName to YLTPortData_<RdbInfoKey> for the current YLTSummary.YLTID
			update YLTsummary
				set TableName=@tableName
				where YLTID=@yltId;

			fetch c3 into @yltId, @rdbInfoKey;

		end;
		close c3;
		deallocate c3;
	end try
	begin catch
		set @msg=ERROR_MESSAGE();
		raiserror (@msg, 16, 1);
	end catch

end;