if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_MakeWCCCODES') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_MakeWCCCODES;
end
go

create procedure absp_MakeWCCCODES
	@fileFolder     varchar(255) = 'C:\\GeoData\\Output Files\\GEODATA',
	@unloadWCCCODES int = 1,
	@isDebug        int = 1,
	@isVerbose      int = 1
as
begin
	--
	--  @fileFolder     is where you want to place the generated HTML files (ie. "c:\html")
	--

	set nocount on;

	declare @checkLogPath char(255);
	declare @filePath varchar(255);
	declare @locator  varchar(40);
	declare @me       varchar(255);
	declare @msg      varchar(max);
	declare @sql      varchar(max);
	declare @str      varchar(max);
	declare @nCounter int;
	declare @nCount   int;
	declare @cnt int;
	declare @loc varchar(40);
	declare @isTmpTableExists int;

	set @me = 'absp_MakeWCCCODES';
	set @msg = 'Starting...';
	exec absp_Util_Log_Info @msg, @me ;

	if exists (select 1 from systemdb.SYS.TABLES where NAME = 'GEODATA')
	begin
		set @msg = 'Back up WCCCODES';
		exec absp_Util_Log_Info @msg, @me ;

		if exists (select 1 from  systemdb.SYS.TABLES where NAME = 'WCCCODES')
		begin
			if exists (select 1 from systemdb.SYS.TABLES where NAME =  'WCCCODES_BACKUP')
			begin
				drop table  systemdb..WCCCODES;
			end
			else
			begin
				exec systemdb..sp_rename 'WCCCODES','WCCCODES_BACKUP';
				if exists(select top(1) name from systemdb.sys.indexes where object_id=object_id('systemdb.dbo.WCCCODES_BACKUP') and name like '%[_]PK')
					exec systemdb..sp_rename 'WCCCODES_PK', 'WCCCODES_BACKUP_PK', N'OBJECT';
			end
		end
		if exists (select 1 from SYS.TABLES where NAME = 'WCCCODES_UNSORTED')
			drop table WCCCODES_UNSORTED;
	end

	execute absp_Util_CreateTableScript @sql out,'WCCCODES','','',1,1,0,'systemdb';
	exec( @sql);
	set @msg = 'Created table WCCCODES...';
	exec absp_Util_Log_Info @msg, @me ;

	execute absp_Util_CreateTableScript @sql out,'WCCCODES','WCCCODES_UNSORTED','',1,1,0;
	exec( @sql)

	set @msg = 'Created table WCCCODES_UNSORTED...';
	exec absp_Util_Log_Info @msg, @me ;

	-- Delete duplicate LOCATORS
	drop index WCCCODES_I1 on WCCCODES_UNSORTED;
	create index WCCCODES_I1 on WCCCODES_UNSORTED (LOCATOR);

	set @msg = 'Insert non-European countries into WCCCODES_UNSORTED from WCCCODES_BACKUP';
	exec absp_Util_Log_Info @msg, @me;
 	insert into WCCCODES_UNSORTED
 		(Locator,Country_ID,State_2,County,Fips,Mapi_Stat,Loc_Type,Zone_Name,Latitude,Longitude,Dist_Coast,Grnd_Elev,Terr_Feat1,Terr_Feat2,Cell_ID,Cresta,Subcresta,CrestaVintage)
	    select Locator,Country_ID,State_2,County,Fips,Mapi_Stat,Loc_Type,Zone_Name,Latitude,Longitude,Dist_Coast,Grnd_Elev,Terr_Feat1,Terr_Feat2,Cell_ID,Cresta,Subcresta,CrestaVintage
	        from systemdb.dbo.WCCCODES_BACKUP where COUNTRY_ID in (select COUNTRY_ID from commondb..COUNTRY where WCCIMPORT <> 'D');

	set @msg = 'Insert GEODATA records into WCCCODES_UNSORTED';
	exec absp_Util_Log_Info @msg, @me;
	insert into WCCCODES_UNSORTED
		(Locator,Country_ID,State_2,County,Fips,Mapi_Stat,Loc_Type,Zone_Name,Latitude,Longitude,Dist_Coast,Grnd_Elev,Terr_Feat1,Terr_Feat2,Cell_ID,Cresta,Subcresta,CrestaVintage)
	    select LOCATOR,COUNTRY_ID,left(FIPS,2),FIPS,FIPS,MAPI_STAT,'GEODATA','Unused',Latitude,Longitude,-999,Grnd_Elev,Terr_Feat1,Terr_Feat2,-999,'Unused','Unused',CrestaVintage
	    	from GEODATA order by GEOROW_KEY desc;

	-- Delete duplicate LOCATORS
	select count(*) as COUNT, LOCATOR into #DUPLOCATORS from WCCCODES_UNSORTED group by LOCATOR having count(*) > 1;

	set @nCounter = 1;

	declare curs3 cursor for
		select COUNT, LOCATOR from #DUPLOCATORS
	open curs3
	fetch curs3 into @cnt, @loc
	while @@fetch_status=0
	begin
		set @nCount = @cnt - 1;
		set @locator = replace(@loc,'''','''''');
		set @sql = 'delete top(' + cast(@nCount as char) + ') from WCCCODES_UNSORTED where LOCATOR = ''' + dbo.trim(@locator)+'''';
		set @msg = 'Delete ' + cast(@nCount as varchar) + ' duplicates for LOCATOR = ' + @loc;
		exec absp_Util_Log_Info @msg, @me ;
		if (@isVerbose > 1)
		begin
			set @msg = 'Query = ' + @sql;
			exec absp_Util_Log_Info @msg, @me ;
		end

		execute (@sql);

		set @nCounter = @nCounter + 1;
		fetch curs3 into @cnt, @loc;
	end

	close curs3;
	deallocate curs3;

	-- SDG__00021006 - We have cites as LOCATORS in WCCCODES that are not unique - they should be removed as they get erroneously handled
	select dbo.trim(COUNTRY_ID) as COUNTRY_ID, dbo.trim(CODE_VALUE) as CODE_VALUE, count(*) as CNT
	    into #DUPCODEVALUE
	    from GEODATA
	    where (MAPI_STAT = 7)
	    group by COUNTRY_ID, CODE_VALUE, LOCATOR
	    having (count(*)>1)
	    order by COUNTRY_ID, CODE_VALUE, count(*);

	delete from WCCCODES_UNSORTED where LOCATOR in
		(select COUNTRY_ID + '-' + CODE_VALUE from #DUPCODEVALUE)
	    and MAPI_STAT = 7;

	set @msg = 'Insert sorted records into WCCCODES from WCCCODES_UNSORTED';
	exec absp_Util_Log_Info @msg, @me ;

	-- Move PRI and Japan
	insert into WCCCODES
		(Locator,Country_ID,State_2,County,Fips,Mapi_Stat,Loc_Type,Zone_Name,Latitude,Longitude,Dist_Coast,Grnd_Elev,Terr_Feat1,Terr_Feat2,Cell_ID,Cresta,Subcresta,CrestaVintage)
			select Locator,Country_ID,State_2,County,Fips,Mapi_Stat,Loc_Type,Zone_Name,Latitude,Longitude,Dist_Coast,Grnd_Elev,Terr_Feat1,Terr_Feat2,Cell_ID,Cresta,Subcresta,CrestaVintage
				from WCCCODES_UNSORTED where COUNTRY_ID in ('00','02') order by COUNTRY_ID, MAPI_STAT, LOCATOR;

	-- Move non-PRI and Japan
	insert into WCCCODES
		(Locator,Country_ID,State_2,County,Fips,Mapi_Stat,Loc_Type,Zone_Name,Latitude,Longitude,Dist_Coast,Grnd_Elev,Terr_Feat1,Terr_Feat2,Cell_ID,Cresta,Subcresta,CrestaVintage)
			select Locator,Country_ID,State_2,County,Fips,Mapi_Stat,Loc_Type,Zone_Name,Latitude,Longitude,Dist_Coast,Grnd_Elev,Terr_Feat1,Terr_Feat2,Cell_ID,Cresta,Subcresta,CrestaVintage
				from WCCCODES_UNSORTED where COUNTRY_ID not in ('00','02') order by COUNTRY_ID, MAPI_STAT, LOCATOR;

	-- Unload WCCCODES to file
	if (@unloadWCCCODES = 1)
	begin
	    set @filePath = @fileFolder + '\\WCCCODES.bar';
	    exec absp_Util_Log_Info @filePath, @me ;
	    exec absp_Util_UnloadData @unloadType='T', @unloadText='WCCCODES', @outFile=@filePath;
		set @filePath = @fileFolder + '\\WCCCODES.txt';
		exec absp_Util_UnloadData @unloadType='T', @unloadText='WCCCODES', @outFile=@filePath, @delimiter='\t';
	end
	else
	begin
		set @msg = 'Error - GEODATA table not found!';
		exec absp_Util_Log_Info @msg, @me;
	end

	set @msg = 'Completed.';
	exec absp_Util_Log_Info @msg, @me;

end;
