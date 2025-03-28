if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CleanupGEODATA') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_CleanupGEODATA;
end
go

create procedure absp_CleanupGEODATA
	@fileFolder varchar(255) = 'C:\\GeoData\\Output Files\\GEODATA',
	@countryId varchar(3) = 'ALL',
	@loadGEODATA  int = 1,
	@checkGEODATA int = 1,
	@createGEODATA2PC int = 0,
	@cleanGEODATA	int = 1,
	@sortGEODATA	int = 1,
	@unloadGEODATA int = 1,
	@makeWCCCODES int = 0,
	@unloadWCCCODES int = 0,
	@isDebug int= 1,
	@isVerbose int = 1
as

begin

	--
	--  @countryId      is a specific 3-char country code to generate (ie. 'BEL')
	--                  Default means do it for all countries in the country table

	SET NOCOUNT ON;

	declare @checkLogPath varchar(255);
	declare @cid      varchar(3);
	declare @filePath varchar(255);
	declare @me       varchar(255);
	declare @msg      varchar(max);
	declare @sql      varchar(max);
	declare @str      varchar(max);
	declare @nCounter integer;
	declare @nCount   integer;
	declare @isTmpTableExists int;
	declare @mapiStat int;
	declare @country  varchar(50);
	declare @qry varchar(max);
	declare @qid int;
	declare @cnt int;
	declare @cv  varchar(50);
	declare @pb1 varchar(50);
	declare @pb2 varchar(50);
	declare @qt varchar(1);
	declare @ms int;
	declare @orderby varchar(max)
	declare @str2 varchar(8000)
	declare @fileexists int;
	declare @crvint varchar(4);
	declare @geostat smallint;
	declare @oldcresta varchar(40);
	declare @newcresta varchar(40);
	declare @oldcv varchar(40);
	declare @newcv varchar(40);

	set @me = 'absp_CleanupGEODATA';
	set @msg = 'Starting...';
	exec absp_Util_Log_Info @msg, @me ;

	-- create the query table
	if exists (select 1 from SYS.TABLES where NAME = 'GEODATA_QUERY')
		drop table GEODATA_QUERY;

	create table GEODATA_QUERY (
		QID INTEGER IDENTITY(1,1) PRIMARY KEY,
		COUNTRY_ID char(3),
		QTYPE char(1),
		QTEXT varchar(max));

	-- create the query results table
	if exists (select 1 from SYS.TABLES where NAME = 'GEODATA_RESULTS')
		drop table GEODATA_RESULTS;

	create table GEODATA_RESULTS (
		QID integer primary key,
		COUNTRY_ID char(3),
		COUNTRY varchar(50),
		COUNT integer default 0,
		QTEXT varchar(max),
		RESULTS varchar(max));

	-- insert check and cleanup/delete queries
	-- QTYPE = C is a check query
	-- QTYPE = D is a delete query

	set @msg = 'Initialize GEODATA_QUERY table';
	exec absp_Util_Log_Info @msg, @me ;

	-- ALL
	insert into GEODATA_QUERY values ('ALL','C','select count(*) as CNT, CODE_VALUE, PBNDY1NAME, PBNDY2NAME, COUNTRY_ID into ##TMPGEOCHECK from GEODATA where MAPI_STAT = 7 group by COUNTRY_ID, CODE_VALUE, PBNDY1NAME, PBNDY2NAME having count(*) > 1 order by COUNTRY_ID');

	-- Set up all of the country specific cleanup queries.  For each country that you need to do something specific, note which country you are in and then add the appropriate queries

	-- Cleanups specific to DEU
	/*  RHK & RN 2-14-14 Not Needed
	insert into GEODATA_QUERY values ('DEU','D','Delete from GEODATA where COUNTRY_ID = ''DEU'' and CODE_VALUE = ''Fuesssen'' and GEO_STAT = 301');
	insert into GEODATA_QUERY values ('DEU','D','Delete from GEODATA where COUNTRY_ID = ''DEU'' and CODE_VALUE = ''Moesssingen'' and GEO_STAT = 301');
	insert into GEODATA_QUERY values ('DEU','D','Delete from GEODATA where COUNTRY_ID = ''DEU'' and CODE_VALUE = ''Vissselhoevede'' and GEO_STAT = 301');
	*/

	-- Cleanups specific to LUX
	insert into GEODATA_QUERY values ('LUX','D','Update GEODATA set Fips=''AB000'', RRgn_Key=2995 where COUNTRY_ID=''LUX'' and RRgn_Key=0');
	insert into GEODATA_QUERY values ('LUX','D','Update GEODATA set PBComb_Key = 0, PBndy1Name = '''', PBndy2Name = '''', Grnd_Elev = -1650 where COUNTRY_ID=''LUX'' and Mapi_Stat = -8 and CrestaVintage = 1999');

	-- Cleanups specific to MCO
	insert into GEODATA_QUERY values ('MCO','D','Delete from GEODATA where COUNTRY_ID = ''MCO'' and Code_Value in (''98'', ''98000'', ''MCO_1'', ''MCO_01'')');
	insert into GEODATA_QUERY values ('MCO','D','Delete from GEODATA where COUNTRY_ID = ''MCO'' and Mapi_Stat in (6)');
	insert into GEODATA_QUERY values ('MCO','D','Update GEODATA set CrestaZone = ''MCO'' where COUNTRY_ID = ''MCO''');
	insert into GEODATA_QUERY values ('MCO','D','Update GEODATA set Fips=''00000'', RRgn_Key=1011, PBComb_Key = 0, PBndy1Name = '''', PBndy2Name = '''', Grnd_Elev = -1650 where COUNTRY_ID=''MCO'' and RRgn_Key=0');
	insert into GEODATA_QUERY values ('MCO','D','Update GEODATA set Fips=''01000'', RRgn_Key=1012, CrestaZone = ''1'', Pseudo_PC = ''99999'' where COUNTRY_ID=''MCO'' and Mapi_Stat <> -8');

	-- RHK  3-25-14  During the creation of GeoData for Country_ID = "NEO", we created bogus records with Mapi_Stat = 8 and 7, we need to delete them
	-- Cleanups specific to NEO (North Europe Offshore)
	insert into GEODATA_QUERY values ('NEO','D','Delete from GEODATA where COUNTRY_ID = ''NEO'' and MAPI_STAT in (7,8)');

	-- Cleanups specific to NOR
	insert into GEODATA_QUERY values ('NOR','D','Delete from GEODATA where COUNTRY_ID = ''NOR'' and GEO_STAT = 202 and Code_Value = ''0'';');

	-- Cleanups specific to ROU
	insert into GEODATA_QUERY values ('ROU','D','Delete from GEODATA where COUNTRY_ID = ''ROU'' and Mun_Code in (''060598'',''102543'');');

	-- End Country specific cleanup queries.

	-- these are the countries we are processing
	select COUNTRY_ID, COUNTRY into #TMPCOUNTRY from commondb..COUNTRY where 1=2;
	insert into #TMPCOUNTRY values ('ALL', 'All European Countries');

	if (@countryId = '' or @countryId = 'ALL')
	begin
		insert into #TMPCOUNTRY select COUNTRY_ID, COUNTRY from commondb..COUNTRY where LOCATION = 'Europe' order by COUNTRY asc;
	end
	else
	begin
		insert into #TMPCOUNTRY select COUNTRY_ID, COUNTRY from commondb..COUNTRY where COUNTRY_ID = @countryId;
	end

	-- load GEODATA_RAW.dbf file as GEODATA
	if (@loadGEODATA = 1)
	begin

		-- preserve GEODATA
		set @msg = 'Backup GEODATA table';
		exec absp_Util_Log_Info @msg, @me;

		if exists (select 1 from systemdb.SYS.TABLES where NAME = 'GEODATA')
		begin
			if exists (select 1 from systemdb.SYS.TABLES where NAME = 'GEODATA_BACKUP')
			begin
				exec absp_Util_Log_Info 'Drop table GEODATA', @me;
				drop table systemdb..GEODATA;
			end
			else
			begin
				exec absp_Util_Log_Info 'Rename table GEODATA to GEODATA_BACKUP', @me;
				exec systemdb..sp_rename 'GEODATA','GEODATA_BACKUP';

				if exists(select top(1) name from systemdb.sys.indexes where object_id=object_Id('systemdb..GEODATA_BACKUP') and name like '%[_]PK')
					exec systemdb..sp_rename 'GEODATA_PK', 'GEODATA_BACKUP_PK', N'OBJECT';
			end
		end

		execute absp_Util_CreateTableScript @sql out,'GEODATA','','',1, 1,0,'systemdb';
		print @sql;
		exec (@sql);
	end

	-- Remove the unique index constraint until we remove duplicates
	drop index GEODATA_I3 on systemdb..GEODATA;
 	create index GEODATA_I3 ON systemdb..GEODATA (CountryKey,Code_Value,Mapi_Stat,CrestaVintage);

	if (@loadGEODATA = 1)
	begin
		-- load GEODATA_RAW with dbisql input
		set @filePath = @fileFolder + '\\GEODATA_RAW.txt';
		exec @fileExists = absp_Util_getfileSizeMB @filepath;

		if (@fileExists >= 0)
		begin
			exec absp_Util_Replace_Slash @str out, @filePath;
			set @filePath = @str;
			exec absp_Util_Log_Info @filePath, @me;
			truncate table systemdb..GEODATA;
			print @filePath;

			--Load table
			exec absp_Util_LoadData 'GEODATA',@filePath,'\t';
		end
	end

	-- only process the country we want
	if (@countryId <> 'ALL')
		delete systemdb..GEODATA where COUNTRY_ID <> @countryId;

	-- run check queries
	if (@checkGEODATA = 1)
	begin

		set @nCounter = 1;
		declare curs1 cursor for
				select dbo.trim(t.COUNTRY),q.COUNTRY_ID,q.QTEXT,q.QID
					from GEODATA_QUERY q, #TMPCOUNTRY t
					where q.COUNTRY_ID = t.COUNTRY_ID
					  and q.QTYPE = 'C'
					order by t.COUNTRY, q.QID
		open curs1
		fetch curs1 into @country,@cid,@qry,@qid
		while @@fetch_status=0
		begin
			set @msg = 'Running check query for ' + dbo.trim(@country )+ ' (' + @cid + ')';

 			exec absp_Util_Log_Info @msg, @me ;
			if (@isVerbose > 0)
			begin
				set @msg = 'Query = ' + @qry;
				exec absp_Util_Log_Info @msg, @me ;
			end;

			exec @isTmpTableExists =  absp_Util_CheckIfTableExists '##TMPGEOCHECK' ;
			if (@isTmpTableExists = 1)
				drop table ##TMPGEOCHECK;

			-- sql file
			set @checkLogPath = @fileFolder + '\\GEODATA_CHECK_' + dbo.trim(@cid) + dbo.trim(cast(@qid as varchar)) + '.sql';
			exec absp_Util_Replace_Slash @str out, @checkLogPath;
			set @checkLogPath = @str;

			--add escape char for <>
			set @qry = replace(replace(@qry,'<','^<'),'>','^>')
			set @str2 = 'echo ' + @qry + ' > "' + @checkLogPath + '"';

			exec xp_cmdshell @str2,no_output;

			exec @isTmpTableExists = absp_Util_CheckIfTableExists '##TMPGEOCHECK' ;
			if (@isTmpTableExists = 1)
			begin
				-- check log
				set @checkLogPath = @fileFolder + '\\GEODATA_CHECK_' +dbo.trim(@cid) + dbo.trim(cast(@qid as varchar)) + '.log';

				exec absp_Util_Replace_Slash @str out, @checkLogPath ;
				set @checkLogPath = @str;
				exec absp_Util_DeleteFile @checkLogPath ;

				select @nCount=count(*) from ##TMPGEOCHECK;

				if (@nCount > 0)
				begin
					print @checkLogPath;
					exec absp_Util_UnloadData 'Q','select * from ##TMPGEOCHECK',@checkLogPath,'\t';

					if (@isVerbose > 0)
						exec  absp_Util_Log_Info @sql, @me ;

				end
				drop table ##TMPGEOCHECK;
			end;

			set @nCounter = @nCounter + 1;
			fetch curs1 into @country,@cid,@qry,@qid;
		end

		close curs1;
		deallocate curs1;
	end

	-- run cleanup queries
	if (@cleanGEODATA = 1)
	begin

		-- country specific cleanup queries
		set @nCounter = 1;
		declare curs2 cursor for
			select dbo.trim(t.COUNTRY), q.COUNTRY_ID, q.QTEXT, q.QID , q.QTYPE
				from GEODATA_QUERY q, #TMPCOUNTRY t
				where q.COUNTRY_ID = t.COUNTRY_ID
				  and q.QTYPE in ('D')
				order by t.COUNTRY, q.QID
		open curs2
		fetch curs2 into @country,@cid,@qry,@qid,@qt
		while @@fetch_status = 0
		begin
			set @msg = 'Running delete query for ' + @country + ' (' + @cid + ')';
			exec absp_Util_Log_Info @msg, @me ;
			if (@isVerbose > 0)
			begin
				set @msg = 'Query = ' + @qry;
				exec absp_Util_Log_Info @msg, @me ;
			end

			-- sql file
			if (@qt = 'C')
				set @checkLogPath = @fileFolder + '\\GEODATA_CHECK_' + dbo.trim(@cid) + dbo.trim(cast(@qid as varchar )) + '.sql';
			else if (@qt = 'D')
				set @checkLogPath = @fileFolder + '\\GEODATA_DELETE_' + dbo.trim(@cid) + dbo.trim(cast(@qid as varchar)) + '.sql';

			exec absp_Util_Replace_Slash @str out, @checkLogPath;
			set @checkLogPath = @str;

			set @str2 = 'echo ' + @qry + ' > ' + @checkLogPath;

			exec xp_cmdshell @str2,no_output;

			exec @isTmpTableExists = absp_Util_CheckIfTableExists '##TMPGEOCHECK' ;
			if (@isTmpTableExists = 1)
				drop table ##TMPGEOCHECK;

			execute(@qry);

			set @nCounter = @nCounter + 1;
			fetch curs2 into @country,@cid,@qry,@qid,@qt;
		end

		close curs2;
		deallocate curs2;


		exec @isTmpTableExists = absp_Util_CheckIfTableExists '#TMPGEODUP';
		if (@isTmpTableExists = 1)
			drop table #TMPGEODUP;


		-- RHK & RN  2-14-14 Departments and 2 digit post codes are no longer the same in France.  We need to map post code 20 to Department 2A
		delete from GEODATA where Country_ID = 'FRA' and MAPI_STAT = 6 and CODE_VALUE = '20';
		insert GEODATA (
				COUNTRYKEY , COUNTRY_ID , CODE_VALUE , CODEVLOCAL , LOCATOR , MUN_CODE , GEO_STAT , MAPI_STAT ,
				LATITUDE , LONGITUDE , CNTRD_TYPE , FIPS , RRGN_KEY , PBCOMB_KEY , PBNDY1NAME , PBNDY2NAME , CRESTAZONE , GRND_ELEV ,
				TERR_FEAT1 , TERR_FEAT2 , PSEUDO_PC , POPULATION , AREA, CrestaVintage
			)
			select
				COUNTRYKEY , COUNTRY_ID , '20', '20', LOCATOR, MUN_CODE , GEO_STAT , 6,
				LATITUDE , LONGITUDE , CNTRD_TYPE , FIPS , RRGN_KEY , PBCOMB_KEY , PBNDY1NAME , PBNDY2NAME , CRESTAZONE , GRND_ELEV ,
				TERR_FEAT1 , TERR_FEAT2 , '20', POPULATION , AREA, CrestaVintage
			from GEODATA
			where Country_ID = 'FRA' and CODE_VALUE = '2A';


		-- AC  2-21-14 Duplicate POL 5-digit PC without hypens in CODE_VALUE
		insert GEODATA (
				COUNTRYKEY , COUNTRY_ID , CODE_VALUE , CODEVLOCAL , LOCATOR , MUN_CODE , GEO_STAT , MAPI_STAT ,
				LATITUDE , LONGITUDE , CNTRD_TYPE , FIPS , RRGN_KEY , PBCOMB_KEY , PBNDY1NAME , PBNDY2NAME , CRESTAZONE , GRND_ELEV ,
				TERR_FEAT1 , TERR_FEAT2 , PSEUDO_PC , POPULATION , AREA, CrestaVintage
			)
			select
				COUNTRYKEY , COUNTRY_ID , replace(CODE_VALUE,'-',''), replace(CODEVLOCAL,'-',''), LOCATOR, MUN_CODE , GEO_STAT , MAPI_STAT,
				LATITUDE , LONGITUDE , CNTRD_TYPE , FIPS , RRGN_KEY , PBCOMB_KEY , PBNDY1NAME , PBNDY2NAME , CRESTAZONE , GRND_ELEV ,
				TERR_FEAT1 , TERR_FEAT2 , replace(PSEUDO_PC,'-',''), POPULATION , AREA, CrestaVintage
			from GEODATA
			where Country_ID = 'POL' and GEO_STAT = 205 and CODE_VALUE like '%-%';


		-- AC  2-21-14 Prepend country_id (XXX_) for high res postal codes
		declare @highresPC table (Country_ID VARCHAR (3), Geo_Stat SMALLINT);
		insert @highresPC values ('AUT',204);
		insert @highresPC values ('BEL',204);
		insert @highresPC values ('CZE',205);
		insert @highresPC values ('DNK',204);
		insert @highresPC values ('EST',205);
		insert @highresPC values ('FIN',205);
		insert @highresPC values ('FRA',205);
		insert @highresPC values ('DEU',205);
		insert @highresPC values ('HUN',204);
		insert @highresPC values ('LVA',204);
		insert @highresPC values ('LTU',205);
		insert @highresPC values ('LUX',202);
		insert @highresPC values ('NLD',204);
		insert @highresPC values ('NOR',204);
		insert @highresPC values ('POL',205);
		insert @highresPC values ('PRT',204);
		insert @highresPC values ('ROU',206);
		insert @highresPC values ('SVK',205);
		insert @highresPC values ('ESP',205);
		insert @highresPC values ('SWE',205);
		insert @highresPC values ('CHE',204);
		insert @highresPC values ('GBR',204);

		declare cursHighres cursor for
				select Country_ID, Geo_Stat
					from @highresPC
					order by Country_ID
		open cursHighres
		fetch cursHighres into @cid, @geostat
		while @@fetch_status=0
		begin
			insert GEODATA (
					COUNTRYKEY , COUNTRY_ID , CODE_VALUE , CODEVLOCAL , LOCATOR , MUN_CODE , GEO_STAT , MAPI_STAT ,
					LATITUDE , LONGITUDE , CNTRD_TYPE , FIPS , RRGN_KEY , PBCOMB_KEY , PBNDY1NAME , PBNDY2NAME , CRESTAZONE , GRND_ELEV ,
					TERR_FEAT1 , TERR_FEAT2 , PSEUDO_PC , POPULATION , AREA, CrestaVintage
				)
				select
					COUNTRYKEY , COUNTRY_ID , COUNTRY_ID + '_' + CODE_VALUE , COUNTRY_ID + '_' + CODEVLOCAL , LOCATOR, MUN_CODE , GEO_STAT , MAPI_STAT,
					LATITUDE , LONGITUDE , CNTRD_TYPE , FIPS , RRGN_KEY , PBCOMB_KEY , PBNDY1NAME , PBNDY2NAME , CRESTAZONE , GRND_ELEV ,
					TERR_FEAT1 , TERR_FEAT2 , PSEUDO_PC , POPULATION , AREA, CrestaVintage
				from GEODATA
				where Country_ID = @cid and GEO_STAT = @geostat;

			fetch cursHighres into @cid, @geostat;
		end

		close cursHighres;
		deallocate cursHighres;


		-- AC  2-20-14 Create old crestas using new alpha crestas
		declare @crestaMap table (Country_ID VARCHAR (3), OldCresta VARCHAR (40), NewCresta VARCHAR (40));
		insert @crestaMap values ('CHE','1','AG');
		insert @crestaMap values ('CHE','2','AR');
		insert @crestaMap values ('CHE','3','AI');
		insert @crestaMap values ('CHE','4','BL');
		insert @crestaMap values ('CHE','5','BS');
		insert @crestaMap values ('CHE','6','BE');
		insert @crestaMap values ('CHE','7','FR');
		insert @crestaMap values ('CHE','8','GE');
		insert @crestaMap values ('CHE','9','GL');
		insert @crestaMap values ('CHE','01','AG');
		insert @crestaMap values ('CHE','02','AR');
		insert @crestaMap values ('CHE','03','AI');
		insert @crestaMap values ('CHE','04','BL');
		insert @crestaMap values ('CHE','05','BS');
		insert @crestaMap values ('CHE','06','BE');
		insert @crestaMap values ('CHE','07','FR');
		insert @crestaMap values ('CHE','08','GE');
		insert @crestaMap values ('CHE','09','GL');
		insert @crestaMap values ('CHE','10','GR');
		insert @crestaMap values ('CHE','11','JU');
		insert @crestaMap values ('CHE','12','LU');
		insert @crestaMap values ('CHE','13','NE');
		insert @crestaMap values ('CHE','14','NW');
		insert @crestaMap values ('CHE','15','OW');
		insert @crestaMap values ('CHE','16','SH');
		insert @crestaMap values ('CHE','17','SZ');
		insert @crestaMap values ('CHE','18','SO');
		insert @crestaMap values ('CHE','19','SG');
		insert @crestaMap values ('CHE','20','TI');
		insert @crestaMap values ('CHE','21','TG');
		insert @crestaMap values ('CHE','22','UR');
		insert @crestaMap values ('CHE','23','VD');
		insert @crestaMap values ('CHE','24','VS');
		insert @crestaMap values ('CHE','25','ZH');
		insert @crestaMap values ('CHE','26','ZG');
		--insert @crestaMap values ('CHE','27','SG');
		-------------------------------------------
		insert @crestaMap values ('IRL','1','CW');
		insert @crestaMap values ('IRL','2','D');
		insert @crestaMap values ('IRL','3','KE');
		insert @crestaMap values ('IRL','4','KK');
		insert @crestaMap values ('IRL','5','LS');
		insert @crestaMap values ('IRL','6','LD');
		insert @crestaMap values ('IRL','7','LH');
		insert @crestaMap values ('IRL','8','MH');
		insert @crestaMap values ('IRL','9','OY');
		insert @crestaMap values ('IRL','01','CW');
		insert @crestaMap values ('IRL','02','D');
		insert @crestaMap values ('IRL','03','KE');
		insert @crestaMap values ('IRL','04','KK');
		insert @crestaMap values ('IRL','05','LS');
		insert @crestaMap values ('IRL','06','LD');
		insert @crestaMap values ('IRL','07','LH');
		insert @crestaMap values ('IRL','08','MH');
		insert @crestaMap values ('IRL','09','OY');
		insert @crestaMap values ('IRL','10','WH');
		insert @crestaMap values ('IRL','11','WX');
		insert @crestaMap values ('IRL','12','WW');
		insert @crestaMap values ('IRL','13','CE');
		insert @crestaMap values ('IRL','14','CO');
		insert @crestaMap values ('IRL','15','KY');
		insert @crestaMap values ('IRL','16','LK');
		insert @crestaMap values ('IRL','17','TA');
		insert @crestaMap values ('IRL','18','WD');
		insert @crestaMap values ('IRL','19','G');
		insert @crestaMap values ('IRL','20','LM');
		insert @crestaMap values ('IRL','21','MO');
		insert @crestaMap values ('IRL','22','RN');
		insert @crestaMap values ('IRL','23','SO');
		insert @crestaMap values ('IRL','24','CN');
		insert @crestaMap values ('IRL','25','DL');
		insert @crestaMap values ('IRL','26','MN');
		--insert @crestaMap values ('IRL','27','G');
		--insert @crestaMap values ('IRL','28','LM');
		--insert @crestaMap values ('IRL','29','MO');
		--insert @crestaMap values ('IRL','30','RN');
		--insert @crestaMap values ('IRL','31','SO');
		--insert @crestaMap values ('IRL','32','CN');
		--insert @crestaMap values ('IRL','33','DL');
		--insert @crestaMap values ('IRL','34','MN');

		declare cursCrestaMap cursor for
				select Country_ID, OldCresta, NewCresta
					from @crestaMap
					order by Country_ID, OldCresta
		open cursCrestaMap
		fetch cursCrestaMap into @cid, @oldcresta, @newcresta
		while @@fetch_status=0
		begin
			insert GEODATA (
					COUNTRYKEY , COUNTRY_ID , CODE_VALUE , CODEVLOCAL , LOCATOR , MUN_CODE , GEO_STAT , MAPI_STAT ,
					LATITUDE , LONGITUDE , CNTRD_TYPE , FIPS , RRGN_KEY , PBCOMB_KEY , PBNDY1NAME , PBNDY2NAME , CRESTAZONE , GRND_ELEV ,
					TERR_FEAT1 , TERR_FEAT2 , PSEUDO_PC , POPULATION , AREA, CrestaVintage
				)
				select
					COUNTRYKEY , COUNTRY_ID , @oldcresta , @oldcresta , LOCATOR , MUN_CODE , GEO_STAT , MAPI_STAT,
					LATITUDE , LONGITUDE , CNTRD_TYPE , FIPS , RRGN_KEY , PBCOMB_KEY , PBNDY1NAME , PBNDY2NAME , CRESTAZONE , GRND_ELEV ,
					TERR_FEAT1 , TERR_FEAT2 , PSEUDO_PC , POPULATION , AREA, CrestaVintage
				from GEODATA
				where Country_ID = @cid and CRESTAZONE = @newcresta;

			fetch cursCrestaMap into @cid, @oldcresta, @newcresta;
		end

		close cursCrestaMap;
		deallocate cursCrestaMap;

		-- Create missing CODE_VALUE = 0 records
		declare @cvMap table (Country_ID VARCHAR (3), OldCV VARCHAR (40), NewCV VARCHAR (40));
		insert @cvMap values ('FIN','00','0');
		insert @cvMap values ('FIN','FIN_00','FIN_0');
		insert @cvMap values ('LTU','00','0');
		insert @cvMap values ('LTU','LTU_00','LTU_0');
		insert @cvMap values ('NOR','00','0');
		insert @cvMap values ('POL','00','0');
		insert @cvMap values ('POL','POL_00','POL_0');
		insert @cvMap values ('ITA','00','0');
		insert @cvMap values ('ITA','ITA_00','ITA_0');

		declare cursCvMap cursor for
				select Country_ID, OldCV, NewCV
					from @cvMap
					order by Country_ID, OldCV
		open cursCvMap
		fetch cursCvMap into @cid, @oldcv, @newcv
		while @@fetch_status=0
		begin
			insert GEODATA (
					COUNTRYKEY , COUNTRY_ID , CODE_VALUE , CODEVLOCAL , LOCATOR , MUN_CODE , GEO_STAT , MAPI_STAT ,
					LATITUDE , LONGITUDE , CNTRD_TYPE , FIPS , RRGN_KEY , PBCOMB_KEY , PBNDY1NAME , PBNDY2NAME , CRESTAZONE , GRND_ELEV ,
					TERR_FEAT1 , TERR_FEAT2 , PSEUDO_PC , POPULATION , AREA, CrestaVintage
				)
				select
					COUNTRYKEY , COUNTRY_ID , @newcv, @newcv, LOCATOR, MUN_CODE , GEO_STAT , MAPI_STAT,
					LATITUDE , LONGITUDE , CNTRD_TYPE , FIPS , RRGN_KEY , PBCOMB_KEY , PBNDY1NAME , PBNDY2NAME , CRESTAZONE , GRND_ELEV ,
					TERR_FEAT1 , TERR_FEAT2 , PSEUDO_PC, POPULATION , AREA, CrestaVintage
				from GEODATA
				where Country_ID = @cid and CODE_VALUE =  @oldcv;

			fetch cursCvMap into @cid, @oldcv, @newcv;
		end

		close cursCvMap;
		deallocate cursCvMap;


		-- Use RQE14 Lat/Long values for Cresta Zones that did not change in 2013
		declare @czLatLong table (Country_ID VARCHAR (3));
		insert @czLatLong values ('AUT');
		insert @czLatLong values ('BEL');
		insert @czLatLong values ('CHE');
		insert @czLatLong values ('CZE');
		insert @czLatLong values ('DEU');
		insert @czLatLong values ('EST');
		insert @czLatLong values ('FIN');
		insert @czLatLong values ('FRA');
		insert @czLatLong values ('GBR');
		insert @czLatLong values ('IRL');
		insert @czLatLong values ('LTU');
		insert @czLatLong values ('LVA');
		insert @czLatLong values ('MCO');
		insert @czLatLong values ('NLD');
		insert @czLatLong values ('POL');
		insert @czLatLong values ('SVK');

		declare cursLatLong cursor for
			select Country_ID from @czLatLong order by Country_ID

		open cursLatLong
		fetch cursLatLong into @cid
		while @@fetch_status=0
		begin
/*
			update g2
				set g2.Latitude = g1.Latitude, g2.Longitude = g1.Longitude
				from GeoData g2 inner join GeodataRQE14 g1
					on g1.Fips = g2.Fips
					and g1.RRgn_Key = g2.RRgn_Key
					and g1.Country_ID = g2.Country_ID
					and g1.Mapi_Stat = g2.Mapi_Stat
					where g2.Country_ID = @cid
						and g2.Mapi_Stat = 8
						and g2.CrestaVintage = '';
*/
			fetch cursLatLong into @cid;
		end

		close cursLatLong;


		-- Use RQE14 Lat/Long values from WccCodes for Cresta Zones that did not change in 2013
		delete @czLatLong;
		insert @czLatLong values ('ESP');
		insert @czLatLong values ('PRT');

		open cursLatLong
		fetch cursLatLong into @cid
		while @@fetch_status=0
		begin
/*
			update g2
				set g2.Latitude = g1.Latitude, g2.Longitude = g1.Longitude
				from GeoData g2 inner join systemdb14..WccCodes g1
					on g1.Fips = g2.Fips
					and g1.Country_ID = g2.Country_ID
					and g1.Mapi_Stat = g2.Mapi_Stat
					where g2.Country_ID = @cid
						and g2.Mapi_Stat = 8
						and g2.CrestaVintage = '';
*/
			fetch cursLatLong into @cid;
		end

		close cursLatLong;
		deallocate cursLatLong;

/*
		-- Use RQE14 Lat/Long values from GeodataRQE14 for 1999 Cresta Zones (CZE)
		update g2
			set g2.Latitude = g1.Latitude, g2.Longitude = g1.Longitude
			from GeoData g2 inner join GeodataRQE14 g1
				on g1.Fips = g2.Fips
				and g1.RRgn_Key = g2.RRgn_Key
				and g1.Country_ID = g2.Country_ID
				and g1.Mapi_Stat = g2.Mapi_Stat
				and g1.CrestaVintage = g2.CrestaVintage
				where g2.Country_ID = 'CZE'
					and g2.Mapi_Stat = 8
					and g2.CrestaVintage = '1999';
*/
/*
		-- Use RQE14 Lat/Long values from WccCodes for 1999 Cresta Zones (ESP, PRT)
		update g2
			set g2.Latitude = g1.Latitude, g2.Longitude = g1.Longitude
			from GeoData g2 inner join systemdb14..WccCodes g1
				on g1.Fips = g2.Fips
				and g1.Country_ID = g2.Country_ID
				and g1.Mapi_Stat = g2.Mapi_Stat
				and g1.CrestaVintage = g2.CrestaVintage
				where g2.Country_ID in ('ESP','PRT')
					and g2.Mapi_Stat = 8
					and g2.CrestaVintage = '1999';
*/

		-- 0009160: Code Fix: Over 1666 cities in geodata does not produce any results due to Import converting tick to underbar in Code_Value
		-- The quick solution was to create duplicate records with underbar in Code_Value instead of tick
		insert GEODATA (
				COUNTRYKEY , COUNTRY_ID , CODE_VALUE , CODEVLOCAL , LOCATOR , MUN_CODE , GEO_STAT , MAPI_STAT ,
				LATITUDE , LONGITUDE , CNTRD_TYPE , FIPS , RRGN_KEY , PBCOMB_KEY , PBNDY1NAME , PBNDY2NAME , CRESTAZONE , GRND_ELEV ,
				TERR_FEAT1 , TERR_FEAT2 , PSEUDO_PC , POPULATION , AREA, CrestaVintage
			)
			select
				COUNTRYKEY , COUNTRY_ID , replace(CODE_VALUE,'''','_') , CODEVLOCAL , LOCATOR , MUN_CODE , GEO_STAT , MAPI_STAT,
				LATITUDE , LONGITUDE , CNTRD_TYPE , FIPS , RRGN_KEY , PBCOMB_KEY , PBNDY1NAME , PBNDY2NAME , CRESTAZONE , GRND_ELEV ,
				TERR_FEAT1 , TERR_FEAT2 , PSEUDO_PC, POPULATION , AREA, CrestaVintage
			from GEODATA
			where MAPI_STAT = 7 and CODE_VALUE like '%''%';


		-- 0010532: Make sure country level Import for Italy is working correctly
		insert GEODATA (
				COUNTRYKEY , COUNTRY_ID , CODE_VALUE , CODEVLOCAL , LOCATOR , MUN_CODE , GEO_STAT , MAPI_STAT ,
				LATITUDE , LONGITUDE , CNTRD_TYPE , FIPS , RRGN_KEY , PBCOMB_KEY , PBNDY1NAME , PBNDY2NAME , CRESTAZONE , GRND_ELEV ,
				TERR_FEAT1 , TERR_FEAT2 , PSEUDO_PC , POPULATION , AREA, CrestaVintage
			)
			select
				COUNTRYKEY , COUNTRY_ID , 'ITA' , 'ITA' , LOCATOR , MUN_CODE , 800 , -8,
				LATITUDE , LONGITUDE , CNTRD_TYPE , FIPS , RRGN_KEY , PBCOMB_KEY , PBNDY1NAME , PBNDY2NAME , CRESTAZONE , GRND_ELEV ,
				TERR_FEAT1 , TERR_FEAT2 , PSEUDO_PC, POPULATION , AREA, CrestaVintage
			from GEODATA
			where CountryKey=47 and Code_Value='00' and Mapi_Stat=8 and CrestaVintage<>'';

		insert GEODATA (
				COUNTRYKEY , COUNTRY_ID , CODE_VALUE , CODEVLOCAL , LOCATOR , MUN_CODE , GEO_STAT , MAPI_STAT ,
				LATITUDE , LONGITUDE , CNTRD_TYPE , FIPS , RRGN_KEY , PBCOMB_KEY , PBNDY1NAME , PBNDY2NAME , CRESTAZONE , GRND_ELEV ,
				TERR_FEAT1 , TERR_FEAT2 , PSEUDO_PC , POPULATION , AREA, CrestaVintage
			)
			select
				COUNTRYKEY , COUNTRY_ID , 'ITA' , 'ITA' , LOCATOR , MUN_CODE , GEO_STAT , -8,
				LATITUDE , LONGITUDE , CNTRD_TYPE , FIPS , RRGN_KEY , PBCOMB_KEY , PBNDY1NAME , PBNDY2NAME , CRESTAZONE , GRND_ELEV ,
				TERR_FEAT1 , TERR_FEAT2 , PSEUDO_PC, POPULATION , AREA, CrestaVintage
			from GEODATA
			where CountryKey=47 and Code_Value='00' and Mapi_Stat=8 and CrestaVintage='';

		-- 0010004: Country-level LUX data does not import
		insert GEODATA (
				COUNTRYKEY , COUNTRY_ID , CODE_VALUE , CODEVLOCAL , LOCATOR , MUN_CODE , GEO_STAT , MAPI_STAT ,
				LATITUDE , LONGITUDE , CNTRD_TYPE , FIPS , RRGN_KEY , PBCOMB_KEY , PBNDY1NAME , PBNDY2NAME , CRESTAZONE , GRND_ELEV ,
				TERR_FEAT1 , TERR_FEAT2 , PSEUDO_PC , POPULATION , AREA, CrestaVintage
			)
			select
				COUNTRYKEY , COUNTRY_ID , CODE_VALUE , CODEVLOCAL , LOCATOR , MUN_CODE , GEO_STAT , -8,
				LATITUDE , LONGITUDE , CNTRD_TYPE , FIPS , RRGN_KEY , PBCOMB_KEY , PBNDY1NAME , PBNDY2NAME , CRESTAZONE , GRND_ELEV ,
				TERR_FEAT1 , TERR_FEAT2 , PSEUDO_PC, POPULATION , AREA, CrestaVintage
			from GEODATA
			where CountryKey=55 and Code_Value='LUX' and Mapi_Stat=8 and CrestaVintage='';


		-- Find and delete duplicates
		select count(*) as COUNT, CODE_VALUE, MAPI_STAT, COUNTRY_ID, CrestaVintage into #TMPGEODUP
			from GEODATA
			group by COUNTRY_ID, CODE_VALUE, MAPI_STAT, CrestaVintage having count(*) > 1 order by COUNTRY_ID;

		if exists (select 1 from SYS.TABLES where NAME = 'TMPGEOROWKEY')
			drop table TMPGEOROWKEY;

		create table TMPGEOROWKEY (GEOROW_KEY int);
		create index TMPGEOROWKEY_I1 on TMPGEOROWKEY (GEOROW_KEY);

		declare curs3 cursor for
			select COUNT,CODE_VALUE,MAPI_STAT,COUNTRY_ID,CrestaVintage from #TMPGEODUP
				order by COUNTRY_ID, CODE_VALUE
		open curs3
		fetch curs3 into @cnt,@cv,@ms,@cid,@crvint
		while @@fetch_status = 0
		begin
			set @nCount = @cnt - 1;
			set @pb1 = replace (@pb1,'''','''''');
			set @pb2 = replace (@pb2,'''','''''');
			set @cv  = replace (@cv, '''','''''');

			set @sql = 'insert into TMPGEOROWKEY select top(' + cast(@nCount as varchar) + ') GEOROW_KEY from GEODATA where CODE_VALUE = ''' + dbo.trim(@cv)+ ''' and MAPI_STAT = ' + cast(@ms as varchar) +
			           ' and COUNTRY_ID = ''' + dbo.trim(@cid) + ''' and CrestaVintage = ''' + @crvint + ''' order by GEO_STAT desc, Population asc';

			if (@isVerbose > 1)
			begin
				set @msg = 'Query = ' + @sql;
				exec absp_Util_Log_Info @msg, @me ;
			end

			execute(@sql);

			set @msg = 'Deleted ' + cast(@nCount as varchar) + ' duplicates for COUNTRY_ID = ''' + dbo.trim(@cid) +
			                                                               ''', CODE_VALUE = ''' + dbo.trim(@cv)  +
			                                                               ''', MAPI_STAT  = '   + cast(@ms as varchar) +
			                                                               ', CrestaVintage = ''' + @crvint + '''';
			if (@isVerbose > 1)
			begin
				exec absp_Util_Log_Info @msg, @me ;
			end

			fetch curs3 into @cnt,@cv,@ms,@cid,@crvint;
		end

		close curs3;
		deallocate curs3;

		-- 0009504: What is the Ground Elevation for Cresta Level Data Used for?
		update GeoData set Grnd_Elev =-1650 where Mapi_Stat = 8;


		-- Pseudo_Pc should NOT be populated with code_value for mapi_stat of 8 when the code_value does not correspond to a 2 or 1 digit postcode.
		update GeoData
			set Pseudo_Pc='99999'
			where Mapi_Stat = 8 and CrestaVintage = '' and Country_ID in
				(select Country_ID from DataVint
					where Zone_Vint = '2012'
					and Zone_Name not in ('1-Digit Postal Code','2-Digit Postal Code')
					and Country_ID not in ('GBR'));


		exec @isTmpTableExists =  absp_Util_CheckIfTableExists '#TMPGEODUP';
		if (@isTmpTableExists = 1)
			drop table #TMPGEODUP;

		delete from GEODATA from GEODATA g
			inner join TMPGEOROWKEY t on g.GEOROW_KEY = t.GEOROW_KEY;

		-- SDG__00020711 - WCe - 3.11.01 Code/DD Fix: absp_checkAllLocatorImport reports invalid locator imports for files constructed for 'W' and 'X' perils
		delete from GEODATA where LOCATOR like '%¾%';

		if exists (select 1 from SYS.TABLES where NAME = 'TMPGEOROWKEY')
			drop table TMPGEOROWKEY;

	end;

	if (@sortGEODATA = 1)
	begin
		-- reset GEODATA.GEOROW_KEY
		if exists (select 1 from SYS.TABLES where NAME = 'GEODATA_REKEY')
			drop table GEODATA_REKEY;

		if exists (select 1 from systemdb.SYS.TABLES where NAME = 'GEODATA')
		begin
			execute absp_Util_CreateTableScript @sql out,'GEODATA','GEODATA_REKEY','',1, 1,0,'systemdb';
	        print @sql;
	        exec (@sql);

			set @msg = 'Reset GEODATA.GEOROW_KEY';
			exec absp_Util_Log_Info @msg, @me ;

			-- create custom Country sort order table
			create table #GEOSORT (
				GEOSORT_KEY INTEGER IDENTITY(1,1) PRIMARY KEY,
				COUNTRYKEY SMALLINT NOT NULL DEFAULT 0,
				COUNTRY_ID CHAR (3)
			);

			set @msg = 'Insert into #GEOSORT';
			exec absp_Util_Log_Info @msg, @me ;
			insert into #GEOSORT (COUNTRY_ID, COUNTRYKEY)
				select distinct COUNTRY_ID, COUNTRYKEY from GEODATA order by COUNTRYKEY;


			-- This is Problem 69 in the spreadsheet (SDG__00020137) Implementing Gfk Postal Code Data in WCe - Integration Defects.xls
			-- When we open the various tables to build GEODATA, we need to order the data to make sure the logical order and physical order is the same.
			-- (RHK noticed the problem in Hungary Cresta Zones)

			-- create custom MAPI_STAT sort order table
			create table #GEOSORTMAPI (
				GEOSORTMAPI_KEY INTEGER IDENTITY(1,1) PRIMARY KEY,
				MAPI_STAT SMALLINT NOT NULL DEFAULT 0,
				ORDERBYCLAUSE VARCHAR(MAX)
			);
			insert into #GEOSORTMAPI (MAPI_STAT, ORDERBYCLAUSE) values (-8, ' order by LOCATOR, CrestaVintage');
			insert into #GEOSORTMAPI (MAPI_STAT, ORDERBYCLAUSE) values ( 8, ' order by GEO_STAT desc, CODE_VALUE, CrestaVintage');
			insert into #GEOSORTMAPI (MAPI_STAT, ORDERBYCLAUSE) values ( 6, ' order by GEO_STAT, CODE_VALUE, CODEVLOCAL, FIPS, RRGN_KEY, PBNDY1NAME, PBNDY2NAME, CrestaVintage');
			insert into #GEOSORTMAPI (MAPI_STAT, ORDERBYCLAUSE) values ( 7, ' order by CODE_VALUE, CODEVLOCAL, GEO_STAT, FIPS, RRGN_KEY, PBNDY1NAME, PBNDY2NAME, CrestaVintage');

			declare curs5 cursor for
				select COUNTRY_ID from #GEOSORT order by GEOSORT_KEY
			open curs5
			fetch curs5 into @cid
			while @@fetch_status = 0
			begin
				declare curs6 cursor for
					select MAPI_STAT , ORDERBYCLAUSE  from #GEOSORTMAPI order by GEOSORTMAPI_KEY
				open curs6
				fetch curs6 into @ms,@orderby
				while @@fetch_status = 0
				begin
					set @sql = 'insert into systemdb.dbo.GEODATA_REKEY ( ' +
								' COUNTRYKEY, COUNTRY_ID, CODE_VALUE, CODEVLOCAL, LOCATOR, MUN_CODE, GEO_STAT, MAPI_STAT, LATITUDE, LONGITUDE,' +
								' CNTRD_TYPE, FIPS, RRGN_KEY, PBCOMB_KEY, PBNDY1NAME, PBNDY2NAME, CRESTAZONE, GRND_ELEV,' +
								' TERR_FEAT1, TERR_FEAT2, PSEUDO_PC, POPULATION, AREA, CrestaVintage' +
								' )' +
								' select distinct COUNTRYKEY, COUNTRY_ID, CODE_VALUE, CODEVLOCAL, LOCATOR, MUN_CODE, GEO_STAT, MAPI_STAT, LATITUDE, LONGITUDE,' +
								'        CNTRD_TYPE, FIPS, RRGN_KEY, PBCOMB_KEY, PBNDY1NAME, PBNDY2NAME, CRESTAZONE, GRND_ELEV,' +
								'        TERR_FEAT1, TERR_FEAT2, PSEUDO_PC, POPULATION, AREA, CrestaVintage' +
								' from systemdb.dbo.GEODATA ' +
								' where COUNTRY_ID = ''' + @cid + '''' +
								'   and MAPI_STAT = ' + cast(@ms as varchar) + ' ' + @orderBy;

					if (@isVerbose > 0)
					begin
						set @msg = 'Query = ' + @sql;
						exec absp_Util_Log_Info @msg, @me ;
					end
					execute(@sql);
					fetch curs6 into @ms,@orderby;
				end

				close curs6;
				deallocate curs6;

				fetch curs5 into @cid;
			end

			close curs5;
        	deallocate curs5;

			if (@isVerbose > 0)
			begin
				set @msg = 'Drop table GEODATA';
				exec absp_Util_Log_Info @msg, @me ;
			end;

			drop table systemdb..GEODATA;

			if (@isVerbose > 0)
			begin
				set @msg = 'Alter table GEODATA_REKEY rename GEODATA';
				exec absp_Util_Log_Info @msg, @me ;
			end

			if not exists (select 1 from systemdb.SYS.TABLES where NAME = 'GEODATA')
			begin
				exec absp_Util_Log_Info 'Rename table GEODATA_REKEY to GEODATA', @me;
				exec systemdb..sp_rename 'GEODATA_REKEY','GEODATA';

				if exists(select top(1) name from systemdb.sys.indexes where object_id=object_Id('systemdb..GEODATA') and name like '%[_]PK')
					exec systemdb..sp_rename 'GEODATA_REKEY_PK', 'GEODATA_PK', N'OBJECT';
			end
		end
		else
		begin
			set @msg = 'Error - GEODATA table not found!';
			exec absp_Util_Log_Info @msg, @me ;
		end
	end

	-- unload GEODATA to file
	if (@unloadGEODATA = 1)
	begin
		set @filePath = @fileFolder + '\\GEODATA.txt';
		exec absp_Util_UnloadData @unloadType='T', @unloadText='GEODATA', @outFile=@filePath, @delimiter='\t';
	end

	-- run make WCCCODES
	if (@makeWCCCODES = 1)
	begin
		exec absp_MakeWCCCODES @fileFolder, @unloadWCCCODES, @isDebug, @isVerbose;
	end

	set @msg = 'Completed.';
	exec absp_Util_Log_Info @msg, @me;
end

/*
exec absp_CleanupGEODATA
	@fileFolder = 'C:\\GeoData\\Output Files\\GEODATA',
	@countryId = 'ALL',
	@loadGEODATA  = 0,
	@checkGEODATA = 0,
	@createGEODATA2PC = 0,
	@cleanGEODATA	= 0,
	@sortGEODATA	= 1,
	@unloadGEODATA = 1;
*/
