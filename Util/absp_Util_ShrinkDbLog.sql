if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_ShrinkDbLog') and objectproperty(ID, N'IsProcedure') = 1)
begin
   drop procedure absp_Util_ShrinkDbLog;
end
go

create procedure absp_Util_ShrinkDbLog @shrinkDbAsWell bit = 0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL

Purpose:		This procedure will attempt to be a singleton that shrinks an EDB logfile.

Returns:        Nothing.

Example call:
				absp_Util_ShrinkDbLog
				absp_Util_ShrinkDbLog 1

====================================================================================================
</pre>
</font>
##BD_END

##PD	@shrinkDbAsWell	^^  If set, then the procedure will shrink the database as well, not just the log.  Be careful.  Could take a long time.

*/
as
begin
	declare @dbName varchar(255);
	declare @sqlQuery varchar(max);
	declare @strValue varchar(255);

	set @dbName = DB_NAME();

	if not exists(select * from SYSOBJECTS where ID = object_id(N'DbShrinkInProgress') and objectproperty(ID, N'IsTable') = 1)
		begin
			begin try
				create table DbShrinkInProgress(StartTime datetime, DoneTime datetime);
				insert into DbShrinkInProgress values (0, 0);
				update DbShrinkInProgress set StartTime = GETDATE();
				update commondb..CFLDRINFO set Attrib = Attrib | 2 where LongName = @dbName;	--lock it

				set @strValue = '1';
				if exists (select 1 from commondb..EngSet where Engine_ID = '20010' and Setting = 'ShrinkThresholdLog')
				begin
					select top 1 @strValue=Value from EngSet where Engine_ID = '20010' and Setting = 'ShrinkThresholdLog';
				end

				set @sqlQuery = 'use [' + @dbName + ']; DBCC SHRINKFILE (' + '''' + @dbName + '_log' + '''' + ', @strValue) WITH NO_INFOMSGS;';
				set @sqlQuery = replace(@sqlQuery, '@strValue', @strValue);
				--print @sqlQuery;
				exec (@sqlQuery);

				if @shrinkDbAsWell = 1
				begin
					set @strValue = '1';
					if exists (select 1 from commondb..EngSet where Engine_ID = '20010' and Setting = 'ShrinkThreshold')
					begin
						select top 1 @strValue=Value from EngSet where Engine_ID = '20010' and Setting = 'ShrinkThreshold';
					end

					set @sqlQuery = 'use [' + @dbName + ']; DBCC SHRINKFILE (' + '''' + @dbName + '''' + ', @strValue) WITH NO_INFOMSGS;';
					set @sqlQuery = replace(@sqlQuery, '@strValue', @strValue);
					--print @sqlQuery;
					exec (@sqlQuery);
				end

				update commondb..CFLDRINFO set Attrib = Attrib & 0xFFFFFFFD where LongName = @dbName;	--unlock it
				update DbShrinkInProgress set DoneTime = GETDATE();
				drop table DbShrinkInProgress;
			end try

			begin catch
				print 'shrink already in progress 1';
			end catch
		end
	else
		begin
			print 'shrink already in progress 2';
		end
end
