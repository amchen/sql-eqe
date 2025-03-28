if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_10817_AddColumsToExposureViews') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_10817_AddColumsToExposureViews;
end
go

create procedure absp_10817_AddColumsToExposureViews

/*
====================================================================================================
Purpose:	This procedure first add a column in IDB and then recreates the EDB view.
			It will be invoked from EDB only.
Returns:	None
====================================================================================================
*/

AS
begin
	set nocount on;

	declare @sql nvarchar(1000);
	declare @curTable varchar(120);
	declare @IDBname varchar(128);


	if exists (select 1 from RQEVersion where DbType='IDB')
	begin
			declare MyCursor cursor fast_forward for select 'ExposedLimitsByPolicy' union select 'ExposedLimitsByRegion' union select 'ExposedLimitsReport'
			open MyCursor
			fetch next from MyCursor into @curTable
			while @@fetch_status = 0
			begin
				--Add column in IDB--
					set @sql = 'if not exists (select 1 from sys.columns where  object_name(object_id)=''' + @curTable +''' and name =''FacLimit'') '
					set @sql = @sql + ' alter table ' + @curTable + ' add FacLimit Float default 0'
					print @sql;
					exec sp_executesql @sql;
					set @sql ='update '  + @curTable + ' set FacLimit=0 where FacLimit is NULL'
					exec sp_executesql @sql;
					print 'IDB column created..'

				fetch next from MyCursor into @curTable;

			end

			close MyCursor;
			deallocate MyCursor;
	end
	else if exists (select 1 from RQEVersion where DbType='EDB')
	begin
		--Since EDB is  migrated first, we need to add the FaacLimit column to IDB and then create the views--
		set @IDBname = DB_NAME() + '_IR';


			declare MyCursor cursor fast_forward for select 'ExposedLimitsByPolicy' union select 'ExposedLimitsByRegion' union select 'ExposedLimitsReport'
			open MyCursor
			fetch next from MyCursor into @curTable
			while @@fetch_status = 0
			begin
				--Add column in IDB--
				if exists(select 1 from sys.sysdatabases where name =@IDBname )
				begin
					set @sql = 'if not exists (select 1 from [' + @IDBname + '].sys.columns where  object_id= object_id(''[' +  @IDBname + '].dbo.' +@curTable + ''') and name =''FacLimit'')'	
					set @sql = @sql + ' alter table [' + @IDBname + '].dbo.' + @curTable + ' add FacLimit Float default 0'
					print @sql;
					exec sp_executesql @sql;
					set @sql ='update [' + @IDBname + '].dbo.' + @curTable + ' set FacLimit=0 where FacLimit is NULL'
					exec sp_executesql @sql;
					print 'IDB column created..'
				end
				
				--Add column in EDB if table exists--for exposed limits report
				if exists(select 1 from sys.tables where name =@curTable)
				begin
					set @sql = 'if not exists (select 1 from sys.columns where object_name(object_id)=''' + @curTable +''' and name =''FacLimit'') '
					set @sql = @sql + ' alter table ' + @curTable + ' add FacLimit Float default 0'
					print @sql;
					exec sp_executesql @sql;
					set @sql ='update ' + @curTable + ' set FacLimit=0 where FacLimit is NULL'
					exec sp_executesql @sql;
					print 'EDB column created..'
				end			
				else
				begin
					-- create views to IDB--	
					set @sql = 'if exists (select * from sys.views where name = ''' + @curTable + ''') drop view  ' + @curTable;
					print @sql;
					exec sp_executesql @sql;
					print 'EDB view dropped..'
					
					set @sql = 'create view ' + @curTable + ' as select * from [' + @IDBname + ']..' + @curTable;
					print @sql;
					exec sp_executesql @sql;
					print 'EDB view created'
				end

				fetch next from MyCursor into @curTable;

			end

			close MyCursor;
			deallocate MyCursor;
		end
	end



