if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_CreateNoDupCITYCT') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_CreateNoDupCITYCT;
end
go

create  procedure absp_CreateNoDupCITYCT  @fileFolder varchar(255), @userName varchar(255)='',@password varchar(255)=''
as
begin

	declare @filePath varchar(255);
	declare @city varchar(40)
	declare @state varchar(2)
	
	-- create and load the cityct table created by bldzipct that may have duplicate records.
	if exists ( select 1 from sys.tables where name = 'CITYCT_3') 
        	drop table CITYCT_3; 

	CREATE TABLE CITYCT_3 (
    		CITY CHAR (40) NULL, THEM_ZIP CHAR (5) NULL, STATE CHAR (2) NULL, COUNTY CHAR (25) NULL, 
    		CITY_TYPE CHAR (1) NULL, FIPS CHAR (5) NULL, LAT NUMERIC (10,6), LON NUMERIC (11,6), 
    		DIST_COAST NUMERIC (8,2), GRND_ELEV NUMERIC (8,2), TERR_FEAT1 NUMERIC (7,5), 
    		TERR_FEAT2 NUMERIC (7,5), SOIL_TYPE CHAR (4) NULL, SOIL_FACT NUMERIC (6,2)
		);
 
	-- load table --
	set @filePath = @fileFolder +  +'\\CITYCT_3.TXT';
    
	exec absp_Util_LoadData 'CITYCT_3', @filePath, '\t';
	
	-- Build a table with only the duplicates
	if exists ( select 1 from sys.tables where name = 'CITYCT_D3' ) 
       	drop table CITYCT_D3;

	CREATE TABLE CITYCT_D3 (
		CITY CHAR (40) NULL, THEM_ZIP CHAR (5) NULL, STATE CHAR (2) NULL, COUNTY CHAR (25) NULL, 
		CITY_TYPE CHAR (1) NULL, FIPS CHAR (5) NULL, LAT NUMERIC (10,6), LON NUMERIC (11,6), 
		DIST_COAST NUMERIC (8,2), GRND_ELEV NUMERIC (8,2), TERR_FEAT1 NUMERIC (7,5), 
		TERR_FEAT2 NUMERIC (7,5), SOIL_TYPE CHAR (4) NULL, SOIL_FACT NUMERIC (6,2), TYPE_ORDER CHAR(1)
	);

	-- CITYCT_D3 contains duplicate CITY/STATE records
	insert into CITYCT_D3
  		select T1.CITY, THEM_ZIP ,T1.STATE ,COUNTY ,CITY_TYPE ,FIPS ,LAT ,LON ,DIST_COAST ,GRND_ELEV ,TERR_FEAT1 ,TERR_FEAT2 ,SOIL_TYPE ,SOIL_FACT,  
   			(case CITY_TYPE when 'T' then '1' when 'A' then '2' when 'P' then '3' end ) as TYPE_ORDER
		from CITYCT_3 T1, (select city, state from cityct_3 group by state, city having count(*) > 1) T2
		where T1.city = T2.city and  T1.state = T2.state;

	-- create another table which holds only the records we want to keep from the duplicates
	if exists ( select 1 from sys.tables where name = 'CITYCT_NODUP') 
		drop table CITYCT_NODUP;
 
	CREATE TABLE CITYCT_NODUP (
     		CITY CHAR (40) NULL, THEM_ZIP CHAR (5) NULL, STATE CHAR (2) NULL, COUNTY CHAR (25) NULL, 
    		CITY_TYPE CHAR (1) NULL, FIPS CHAR (5) NULL, LAT NUMERIC (10,6), LON NUMERIC (11,6), 
    		DIST_COAST NUMERIC (8,2), GRND_ELEV NUMERIC (8,2), TERR_FEAT1 NUMERIC (7,5), 
    		TERR_FEAT2 NUMERIC (7,5), SOIL_TYPE CHAR (4) NULL, SOIL_FACT NUMERIC (6,2)
	);

	declare curs1 cursor for
		SELECT distinct CITY ,STATE 
		FROM CITYCT_D3 
    		group by CITY ,STATE, TYPE_ORDER
		order by STATE, CITY;
 	open curs1;
 	fetch curs1 into @city,@state;
 	while @@fetch_status=0
 	begin
		-- CITYCT_NODUP contains non-duplicate CITY/STATE records with the lowest THEM_ZIP
		-- if there are duplicate CITY/STATE records with different THEM_ZIP
   		insert into CITYCT_NODUP
			select top 1 T1.CITY, T1.THEM_ZIP, T1.STATE, T1.COUNTY, T1.CITY_TYPE, T1.FIPS, T1.LAT, T1.LON,
				T1.DIST_COAST, T1.GRND_ELEV, T1.TERR_FEAT1, T1.TERR_FEAT2, T1.SOIL_TYPE, T1.SOIL_FACT 
			from CITYCT_D3 T1
			where T1.CITY = @city and T1.STATE = @state 
				order by T1.STATE, T1.CITY, T1.TYPE_ORDER, T1.THEM_ZIP;
		fetch curs1 into @city,@state;
	end
	close curs1;
	deallocate curs1;

	-- Delete all the duplicate records from CITYCT_3
	delete CITYCT_3
		from CITYCT_3 T1 inner join CITYCT_D3 T2 on 
			T1.CITY = T2.CITY and
			T1.STATE = T2.STATE and
			T1.COUNTY = T2.COUNTY and
			T1.CITY_TYPE = T2.CITY_TYPE and
			T1.LAT = T2.LAT and
			T1.LON = T2.LON;

	-- insert the records we want to keep into CITYCT_3
	insert into CITYCT_3 select * from CITYCT_NODUP;

	-- Unload table as a bar-delimited CITYCT.txt
	set @filePath = @fileFolder +  +'\\CITYCT.txt';

	exec absp_Util_unLoadData 'Q','select * from CITYCT_3 order by state, city', @filePath, '|', @userName, @password;

end;
