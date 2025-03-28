if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_CompareTestStats') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_CompareTestStats 
end
go

create procedure absp_CompareTestStats @tablename varchar(100)='', @TestNum int=0, @CompareTable1 varchar(230)='',@CompareTable2 varchar(232)=''
as 
BEGIN
	declare @dbName varchar(150)
	declare @irDBName varchar(150)
	declare @sql varchar(max)
	declare @ErrMessage varchar(50)

if ((@tablename='') and (@TestNum!=0)) or ((@TestNum=0) and (@CompareTable1='' or @CompareTable2=''))
	begin
		set @ErrMessage= N'%s';
			RAISERROR (@ErrMessage, 16, 1,'No TableName passed!');
			return
        end

if (@TestNum=0)
	begin
		set @sql='SELECT     a.Tablename, a.Rcount as '''+@CompareTable1+''', b.Rcount as '''+@CompareTable2+''''+', (a.Rcount-b.Rcount) as ''Diff''
		FROM '+@CompareTable1+' AS a INNER JOIN '++@CompareTable2++' AS b ON a.Tablename = b.Tablename'
		execute (@sql)
		return;
	end

	set @sql='if exists(select 1 from sys.objects where name='''+@tablename+''') drop table '+@tablename;  execute (@sql);
	set @sql='create table '+@tablename+'( Tablename varchar(50), Rcount int)' execute (@sql);

		set @dbName =DB_NAME();
		exec absp_getDBName  @dbName out, @dbName, 0; -- Enclose within brackets--

		if RIGHT(rtrim(@dbName),4) != '_IR]'
			exec absp_getDBName  @irDBName out, @dbName, 1;
		else
			set @irDBName = @dbName;


	if (@TestNum=1)
	begin		
		set @sql='insert '+@tablename+'	select ''	exposurereport 	'',	count(*) from 		exposurereport 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortAEP 	'',	count(*) from 		ResPPortAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortAEPEx 	'',	count(*) from 		ResPPortAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortAEPTVaR 	'',	count(*) from 		ResPPortAEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortAEPTVaREx 	'',	count(*) from 		ResPPortAEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortByAccount 	'',	count(*) from 		ResPPortByAccount 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortByBranch 	'',	count(*) from 		ResPPortByBranch 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortByCompany 	'',	count(*) from 		ResPPortByCompany 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortByCountry 	'',	count(*) from 		ResPPortByCountry 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortByCoverage 	'',	count(*) from 		ResPPortByCoverage 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortByCustomRgnAEP 	'',	count(*) from 		ResPPortByCustomRgnAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortByDivision 	'',	count(*) from 		ResPPortByDivision 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortByLoB 	'',	count(*) from 		ResPPortByLoB 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortByPostCode 	'',	count(*) from 		ResPPortByPostCode 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortByProducer 	'',	count(*) from 		ResPPortByProducer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortByRegion 	'',	count(*) from 		ResPPortByRegion 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortBySite 	'',	count(*) from 		ResPPortBySite 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortByStructureCoverage 	'',	count(*) from 		ResPPortByStructureCoverage 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortBySubRegion 	'',	count(*) from 		ResPPortBySubRegion 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortLFSByIntensity 	'',	count(*) from 		ResPPortLFSByIntensity 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortOEP 	'',	count(*) from 		ResPPortOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortOEPEx 	'',	count(*) from 		ResPPortOEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortOEPTVaR 	'',	count(*) from 		ResPPortOEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResPPortOEPTVaREx 	'',	count(*) from 		ResPPortOEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	SP_FILES 	'',	count(*) from 		SP_FILES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByCountryData	'',	count(*) from 		ELTByCountryData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByLayerData	'',	count(*) from 		ELTByLayerData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByPolicyData	'',	count(*) from 		ELTByPolicyData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByRegionData	'',	count(*) from 		ELTByRegionData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTBySiteData	'',	count(*) from 		ELTBySiteData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTBySubRegionData	'',	count(*) from 		ELTBySubRegionData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTPortData	'',	count(*) from 		ELTPortData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	RTROINTR	'',	count(*) from '+@irDBName+'..'+' 		RTROINTR	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 RTROINTRD	'',	count(*) from '+@irDBName+'..'+' 		 RTROINTRD	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 RTROINTRF	'',	count(*) from '+@irDBName+'..'+' 		 RTROINTRF	' execute (@sql);
	end

	if (@TestNum=2)
	begin	
		set @sql='insert '+@tablename+'	select ''	 ResRAccAEP 	'',	count(*) from 		 ResRAccAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccAEPEx 	'',	count(*) from 		 ResRAccAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccByLayer 	'',	count(*) from 		 ResRAccByLayer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccByTreaty 	'',	count(*) from 		 ResRAccByTreaty 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccOEP 	'',	count(*) from 		 ResRAccOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccOEPEx 	'',	count(*) from 		 ResRAccOEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByCountryData	'',	count(*) from 		ELTByCountryData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByLayerData	'',	count(*) from 		ELTByLayerData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByPolicyData	'',	count(*) from 		ELTByPolicyData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByRegionData	'',	count(*) from 		ELTByRegionData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTBySiteData	'',	count(*) from 		ELTBySiteData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTBySubRegionData	'',	count(*) from 		ELTBySubRegionData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTPortData	'',	count(*) from 		ELTPortData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	DMGRES 	'',	count(*) from '+@irDBName+'..'+' 		DMGRES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 DMGRESB 	'',	count(*) from '+@irDBName+'..'+' 		 DMGRESB 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ExpPolA 	'',	count(*) from '+@irDBName+'..'+' 		 ExpPolA 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ExpRes 	'',	count(*) from '+@irDBName+'..'+' 		 ExpRes 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ExpResB 	'',	count(*) from '+@irDBName+'..'+' 		 ExpResB 	' execute (@sql);
	end
	
	if (@TestNum=3)
	begin		
		set @sql='insert '+@tablename+'	select ''	ResRPortAEP	'',	count(*) from 		ResRPortAEP	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRPortAEPEx	'',	count(*) from 		ResRPortAEPEx	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRPortAEPTVaR	'',	count(*) from 		ResRPortAEPTVaR	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRPortAEPTVaREx	'',	count(*) from 		ResRPortAEPTVaREx	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRPortByCountry	'',	count(*) from 		ResRPortByCountry	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRPortByCustomRgnAEP	'',	count(*) from 		ResRPortByCustomRgnAEP	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRPortByDivision	'',	count(*) from 		ResRPortByDivision	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRPortByProducer	'',	count(*) from 		ResRPortByProducer	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRPortByProgram	'',	count(*) from 		ResRPortByProgram	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRPortByRegion	'',	count(*) from 		ResRPortByRegion	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRPortByRiskType	'',	count(*) from 		ResRPortByRiskType	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRPortByTreatyType	'',	count(*) from 		ResRPortByTreatyType	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRPortLFSByIntensity	'',	count(*) from 		ResRPortLFSByIntensity	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRPortOEP	'',	count(*) from 		ResRPortOEP	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRPortOEPEx	'',	count(*) from 		ResRPortOEPEx	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRPortOEPTVaR	'',	count(*) from 		ResRPortOEPTVaR	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRAccByLayer	'',	count(*) from 		ResRAccByLayer	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRAccByTreaty	'',	count(*) from 		ResRAccByTreaty	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRTrtyAEP	'',	count(*) from 		ResRTrtyAEP	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRTrtyAEPEx	'',	count(*) from 		ResRTrtyAEPEx	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRTrtyByCustomRgnAEP	'',	count(*) from 		ResRTrtyByCustomRgnAEP	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRTrtyByLayer	'',	count(*) from 		ResRTrtyByLayer	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRTrtyByRegion	'',	count(*) from 		ResRTrtyByRegion	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRTrtyByReinstatement	'',	count(*) from 		ResRTrtyByReinstatement	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRTrtyOEP	'',	count(*) from 		ResRTrtyOEP	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRTrtyOEPEx	'',	count(*) from 		ResRTrtyOEPEx	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRAccAEP	'',	count(*) from 		ResRAccAEP	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRAccAEPEx	'',	count(*) from 		ResRAccAEPEx	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRAccByRiskType	'',	count(*) from 		ResRAccByRiskType	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRAccOEP	'',	count(*) from 		ResRAccOEP	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRAccOEPEx	'',	count(*) from 		ResRAccOEPEx	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ResRPortByProgram	'',	count(*) from 		ResRPortByProgram	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByCountryData	'',	count(*) from 		ELTByCountryData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByLayerData	'',	count(*) from 		ELTByLayerData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByPolicyData	'',	count(*) from 		ELTByPolicyData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByRegionData	'',	count(*) from 		ELTByRegionData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTBySiteData	'',	count(*) from 		ELTBySiteData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTBySubRegionData	'',	count(*) from 		ELTBySubRegionData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTPortData	'',	count(*) from 		ELTPortData	' execute (@sql);

		set @sql='insert '+@tablename+'	select ''	Progrs_a 	'',	count(*) from '+@irDBName+'..'+' 		Progrs_a 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	Progrs_p 	'',	count(*) from '+@irDBName+'..'+' 		Progrs_p 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	TrtyRec 	'',	count(*) from '+@irDBName+'..'+' 		TrtyRec 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	RTRORES 	'',	count(*) from '+@irDBName+'..'+' 		RTRORES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	RTRORESA 	'',	count(*) from '+@irDBName+'..'+' 		RTRORESA 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	RTRORESD 	'',	count(*) from '+@irDBName+'..'+' 		RTRORESD 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	DMGRES 	'',	count(*) from '+@irDBName+'..'+' 		DMGRES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	DMGRESB 	'',	count(*) from '+@irDBName+'..'+' 		DMGRESB 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ExpPolA 	'',	count(*) from '+@irDBName+'..'+' 		ExpPolA 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ExpRes 	'',	count(*) from '+@irDBName+'..'+' 		ExpRes 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ExpResB	'',	count(*) from '+@irDBName+'..'+' 		ExpResB	' execute (@sql);
				
	end

	if (@TestNum=4)
	begin
		set @sql='insert '+@tablename+'	select ''	exposurereport 	'',	count(*) from 		exposurereport 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  exposurevalue 	'',	count(*) from 		  exposurevalue 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortAEP 	'',	count(*) from 		  ResRPortAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortAEPEx 	'',	count(*) from 		  ResRPortAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortAEPTVaR 	'',	count(*) from 		  ResRPortAEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortAEPTVaREx 	'',	count(*) from 		  ResRPortAEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByCountry 	'',	count(*) from 		  ResRPortByCountry 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByCustomRgnAEP 	'',	count(*) from 		  ResRPortByCustomRgnAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByDivision 	'',	count(*) from 		  ResRPortByDivision 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByProducer 	'',	count(*) from 		  ResRPortByProducer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByProgram 	'',	count(*) from 		  ResRPortByProgram 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByRegion 	'',	count(*) from 		  ResRPortByRegion 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByTreatyType 	'',	count(*) from 		  ResRPortByTreatyType 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortLFSByIntensity 	'',	count(*) from 		  ResRPortLFSByIntensity 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortOEP 	'',	count(*) from 		  ResRPortOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortOEPEx 	'',	count(*) from 		  ResRPortOEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortOEPTVaR 	'',	count(*) from 		  ResRPortOEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortOEPTVaREx 	'',	count(*) from 		  ResRPortOEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 SP_FILES 	'',	count(*) from 		 SP_FILES 	' execute (@sql);
									
		set @sql='insert '+@tablename+'	select ''	Progrs_a 	'',	count(*) from '+@irDBName+'..'+' 		Progrs_a 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	Progrs_p 	'',	count(*) from '+@irDBName+'..'+' 		Progrs_p 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	TrtyRec 	'',	count(*) from '+@irDBName+'..'+' 		TrtyRec 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	RTRORES 	'',	count(*) from '+@irDBName+'..'+' 		RTRORES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	RTRORESA 	'',	count(*) from '+@irDBName+'..'+' 		RTRORESA 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	RTRORESD 	'',	count(*) from '+@irDBName+'..'+' 		RTRORESD 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	DMGRES 	'',	count(*) from '+@irDBName+'..'+' 		DMGRES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	DMGRESB 	'',	count(*) from '+@irDBName+'..'+' 		DMGRESB 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ExpPolA 	'',	count(*) from '+@irDBName+'..'+' 		ExpPolA 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ExpRes 	'',	count(*) from '+@irDBName+'..'+' 		ExpRes 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ExpResB 	'',	count(*) from '+@irDBName+'..'+' 		ExpResB 	' execute (@sql);
	end


	if (@TestNum=5)
	begin
		set @sql='insert '+@tablename+'	select ''	exposurereport 	'',	count(*) from 		exposurereport 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  exposurevalue 	'',	count(*) from 		  exposurevalue 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortAEP 	'',	count(*) from 		  ResRPortAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortAEPEx 	'',	count(*) from 		  ResRPortAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortAEPTVaR 	'',	count(*) from 		  ResRPortAEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortAEPTVaREx 	'',	count(*) from 		  ResRPortAEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByCountry 	'',	count(*) from 		  ResRPortByCountry 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByCustomRgnAEP 	'',	count(*) from 		  ResRPortByCustomRgnAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByDivision 	'',	count(*) from 		  ResRPortByDivision 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByProducer 	'',	count(*) from 		  ResRPortByProducer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByProgram 	'',	count(*) from 		  ResRPortByProgram 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByRegion 	'',	count(*) from 		  ResRPortByRegion 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByTreatyType 	'',	count(*) from 		  ResRPortByTreatyType 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortLFSByIntensity 	'',	count(*) from 		  ResRPortLFSByIntensity 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortOEP 	'',	count(*) from 		  ResRPortOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortOEPEx 	'',	count(*) from 		  ResRPortOEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortOEPTVaR 	'',	count(*) from 		  ResRPortOEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortOEPTVaREx 	'',	count(*) from 		  ResRPortOEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 SP_FILES 	'',	count(*) from 		 SP_FILES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccAEP 	'',	count(*) from 		 ResRAccAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccAEPEx 	'',	count(*) from 		 ResRAccAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccByLayer 	'',	count(*) from 		 ResRAccByLayer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccByTreaty 	'',	count(*) from 		 ResRAccByTreaty 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccOEP 	'',	count(*) from 		 ResRAccOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccOEPEx 	'',	count(*) from 		 ResRAccOEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyAEP 	'',	count(*) from 		 ResRTrtyAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyAEPEx 	'',	count(*) from 		 ResRTrtyAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyByCustomRgnAEP 	'',	count(*) from 		 ResRTrtyByCustomRgnAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyByLayer 	'',	count(*) from 		 ResRTrtyByLayer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyByRegion 	'',	count(*) from 		 ResRTrtyByRegion 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyByReinstatement 	'',	count(*) from 		 ResRTrtyByReinstatement 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyOEP 	'',	count(*) from 		 ResRTrtyOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyOEPEx 	'',	count(*) from 		 ResRTrtyOEPEx 	' execute (@sql);
									
		set @sql='insert '+@tablename+'	select ''	Progrs_a 	'',	count(*) from '+@irDBName+'..'+' 		Progrs_a 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	Progrs_p 	'',	count(*) from '+@irDBName+'..'+' 		Progrs_p 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	TrtyRec 	'',	count(*) from '+@irDBName+'..'+' 		TrtyRec 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	RTRORES 	'',	count(*) from '+@irDBName+'..'+' 		RTRORES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	RTRORESA 	'',	count(*) from '+@irDBName+'..'+' 		RTRORESA 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	RTRORESD 	'',	count(*) from '+@irDBName+'..'+' 		RTRORESD 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	DMGRES 	'',	count(*) from '+@irDBName+'..'+' 		DMGRES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	DMGRESB 	'',	count(*) from '+@irDBName+'..'+' 		DMGRESB 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ExpPolA 	'',	count(*) from '+@irDBName+'..'+' 		ExpPolA 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ExpRes 	'',	count(*) from '+@irDBName+'..'+' 		ExpRes 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ExpResB 	'',	count(*) from '+@irDBName+'..'+' 		ExpResB 	' execute (@sql);
	end

	if (@TestNum=6)
	begin
		set @sql='insert '+@tablename+'	select ''	exposurereport 	'',	count(*) from 		exposurereport 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  exposurevalue 	'',	count(*) from 		  exposurevalue 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortAEP 	'',	count(*) from 		  ResRPortAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortAEPEx 	'',	count(*) from 		  ResRPortAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortAEPTVaR 	'',	count(*) from 		  ResRPortAEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortAEPTVaREx 	'',	count(*) from 		  ResRPortAEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByCountry 	'',	count(*) from 		  ResRPortByCountry 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByCustomRgnAEP 	'',	count(*) from 		  ResRPortByCustomRgnAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByDivision 	'',	count(*) from 		  ResRPortByDivision 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByProducer 	'',	count(*) from 		  ResRPortByProducer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByProgram 	'',	count(*) from 		  ResRPortByProgram 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByRegion 	'',	count(*) from 		  ResRPortByRegion 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortByTreatyType 	'',	count(*) from 		  ResRPortByTreatyType 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortLFSByIntensity 	'',	count(*) from 		  ResRPortLFSByIntensity 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortOEP 	'',	count(*) from 		  ResRPortOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortOEPEx 	'',	count(*) from 		  ResRPortOEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortOEPTVaR 	'',	count(*) from 		  ResRPortOEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResRPortOEPTVaREx 	'',	count(*) from 		  ResRPortOEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 SP_FILES 	'',	count(*) from 		 SP_FILES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccAEP 	'',	count(*) from 		 ResRAccAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccAEPEx 	'',	count(*) from 		 ResRAccAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccByLayer 	'',	count(*) from 		 ResRAccByLayer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccByTreaty 	'',	count(*) from 		 ResRAccByTreaty 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccOEP 	'',	count(*) from 		 ResRAccOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccOEPEx 	'',	count(*) from 		 ResRAccOEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyAEP 	'',	count(*) from 		 ResRTrtyAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyAEPEx 	'',	count(*) from 		 ResRTrtyAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyByCustomRgnAEP 	'',	count(*) from 		 ResRTrtyByCustomRgnAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyByLayer 	'',	count(*) from 		 ResRTrtyByLayer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyByRegion 	'',	count(*) from 		 ResRTrtyByRegion 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyByReinstatement 	'',	count(*) from 		 ResRTrtyByReinstatement 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyOEP 	'',	count(*) from 		 ResRTrtyOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyOEPEx 	'',	count(*) from 		 ResRTrtyOEPEx 	' execute (@sql);
									
		set @sql='insert '+@tablename+'	select ''	Progrs_a 	'',	count(*) from '+@irDBName+'..'+' 		Progrs_a 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	Progrs_p 	'',	count(*) from '+@irDBName+'..'+' 		Progrs_p 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	TrtyRec 	'',	count(*) from '+@irDBName+'..'+' 		TrtyRec 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	RTRORES 	'',	count(*) from '+@irDBName+'..'+' 		RTRORES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	RTRORESA 	'',	count(*) from '+@irDBName+'..'+' 		RTRORESA 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	RTRORESD 	'',	count(*) from '+@irDBName+'..'+' 		RTRORESD 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	DMGRES 	'',	count(*) from '+@irDBName+'..'+' 		DMGRES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	DMGRESB 	'',	count(*) from '+@irDBName+'..'+' 		DMGRESB 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ExpPolA 	'',	count(*) from '+@irDBName+'..'+' 		ExpPolA 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ExpRes 	'',	count(*) from '+@irDBName+'..'+' 		ExpRes 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ExpResB 	'',	count(*) from '+@irDBName+'..'+' 		ExpResB 	' execute (@sql);
	end

	if (@TestNum in (8,9,10))
	begin
		set @sql='insert '+@tablename+'	select ''	 ResAPortAEP 	'',	count(*) from 		 ResAPortAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortAEPEx 	'',	count(*) from 		  ResAPortAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortAEPTVaR 	'',	count(*) from 		  ResAPortAEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortAEPTVaREx 	'',	count(*) from 		  ResAPortAEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortByCountry 	'',	count(*) from 		  ResAPortByCountry 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortByCustomRgnNetPreCatOEP 	'',	count(*) from 		  ResAPortByCustomRgnNetPreCatOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortByCustomRgnRecByTreatyOEP 	'',	count(*) from 		  ResAPortByCustomRgnRecByTreatyOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortByLayer 	'',	count(*) from 		  ResAPortByLayer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortByPortfolio 	'',	count(*) from 		  ResAPortByPortfolio 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortByRegion 	'',	count(*) from 		  ResAPortByRegion 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortByReinsurer 	'',	count(*) from 		  ResAPortByReinsurer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortByTreaty 	'',	count(*) from 		  ResAPortByTreaty 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortLFSByIntensity 	'',	count(*) from 		  ResAPortLFSByIntensity 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortOEP 	'',	count(*) from 		  ResAPortOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortOEPEx 	'',	count(*) from 		  ResAPortOEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortOEPTVaR 	'',	count(*) from 		  ResAPortOEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortOEPTVaREx 	'',	count(*) from 		  ResAPortOEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortReinstByLayer 	'',	count(*) from 		  ResAPortReinstByLayer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortReinstByReinsurer 	'',	count(*) from 		  ResAPortReinstByReinsurer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortReinstByTreaty 	'',	count(*) from 		 ResAPortReinstByTreaty 	' execute (@sql);
	end

	if (@TestNum=12)
	begin
		set @sql='insert '+@tablename+'	select ''	 ResAPortAEP 	'',	count(*) from 		 ResAPortAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortAEPEx 	'',	count(*) from 		  ResAPortAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortAEPTVaR 	'',	count(*) from 		  ResAPortAEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortAEPTVaREx 	'',	count(*) from 		  ResAPortAEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortByCountry 	'',	count(*) from 		  ResAPortByCountry 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortByCustomRgnNetPreCatOEP 	'',	count(*) from 		  ResAPortByCustomRgnNetPreCatOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortByCustomRgnRecByTreatyOEP 	'',	count(*) from 		  ResAPortByCustomRgnRecByTreatyOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortByLayer 	'',	count(*) from 		  ResAPortByLayer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortByPortfolio 	'',	count(*) from 		  ResAPortByPortfolio 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortByRegion 	'',	count(*) from 		  ResAPortByRegion 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortByReinsurer 	'',	count(*) from 		  ResAPortByReinsurer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortByTreaty 	'',	count(*) from 		  ResAPortByTreaty 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortLFSByIntensity 	'',	count(*) from 		  ResAPortLFSByIntensity 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortOEP 	'',	count(*) from 		  ResAPortOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortOEPEx 	'',	count(*) from 		  ResAPortOEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortOEPTVaR 	'',	count(*) from 		  ResAPortOEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortOEPTVaREx 	'',	count(*) from 		  ResAPortOEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortReinstByLayer 	'',	count(*) from 		  ResAPortReinstByLayer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	  ResAPortReinstByReinsurer 	'',	count(*) from 		  ResAPortReinstByReinsurer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortReinstByTreaty 	'',	count(*) from 		 ResAPortReinstByTreaty 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 exposurereport 	'',	count(*) from 		 exposurereport 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortAEP 	'',	count(*) from 		 ResPPortAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortAEPEx 	'',	count(*) from 		 ResPPortAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortAEPTVaR 	'',	count(*) from 		 ResPPortAEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortAEPTVaREx 	'',	count(*) from 		 ResPPortAEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortByAccount 	'',	count(*) from 		 ResPPortByAccount 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortByBranch 	'',	count(*) from 		 ResPPortByBranch 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortByCompany 	'',	count(*) from 		 ResPPortByCompany 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortByCountry 	'',	count(*) from 		 ResPPortByCountry 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortByCoverage 	'',	count(*) from 		 ResPPortByCoverage 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortByCustomRgnAEP 	'',	count(*) from 		 ResPPortByCustomRgnAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortByDivision 	'',	count(*) from 		 ResPPortByDivision 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortByLoB 	'',	count(*) from 		 ResPPortByLoB 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortByPostCode 	'',	count(*) from 		 ResPPortByPostCode 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortByProducer 	'',	count(*) from 		 ResPPortByProducer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortByRegion 	'',	count(*) from 		 ResPPortByRegion 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortBySite 	'',	count(*) from 		 ResPPortBySite 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortByStructureCoverage 	'',	count(*) from 		 ResPPortByStructureCoverage 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortBySubRegion 	'',	count(*) from 		 ResPPortBySubRegion 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortLFSByIntensity 	'',	count(*) from 		 ResPPortLFSByIntensity 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortOEP 	'',	count(*) from 		 ResPPortOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortOEPEx 	'',	count(*) from 		 ResPPortOEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortOEPTVaR 	'',	count(*) from 		 ResPPortOEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResPPortOEPTVaREx 	'',	count(*) from 		 ResPPortOEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 SP_FILES 	'',	count(*) from 		 SP_FILES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByCountryData	'',	count(*) from 		ELTByCountryData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByLayerData	'',	count(*) from 		ELTByLayerData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByPolicyData	'',	count(*) from 		ELTByPolicyData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByRegionData	'',	count(*) from 		ELTByRegionData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTBySiteData	'',	count(*) from 		ELTBySiteData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTBySubRegionData	'',	count(*) from 		ELTBySubRegionData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTPortData	'',	count(*) from 		ELTPortData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	RTROINTR	'',	count(*) from '+@irDBName+'..'+' 		RTROINTR	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 RTROINTRD	'',	count(*) from '+@irDBName+'..'+' 		 RTROINTRD	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 RTROINTRF	'',	count(*) from '+@irDBName+'..'+' 		 RTROINTRF	' execute (@sql);	
	end

	if (@TestNum=13)
	begin
		set @sql='insert '+@tablename+'	select ''	ResAPortAEP 	'',	count(*) from 		ResAPortAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortAEPEx 	'',	count(*) from 		 ResAPortAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortAEPTVaR 	'',	count(*) from 		 ResAPortAEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortAEPTVaREx 	'',	count(*) from 		 ResAPortAEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortByCountry 	'',	count(*) from 		 ResAPortByCountry 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortByCustomRgnNetPreCatOEP 	'',	count(*) from 		 ResAPortByCustomRgnNetPreCatOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortByCustomRgnRecByTreatyOEP 	'',	count(*) from 		 ResAPortByCustomRgnRecByTreatyOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortByLayer 	'',	count(*) from 		 ResAPortByLayer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortByPortfolio 	'',	count(*) from 		 ResAPortByPortfolio 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortByRegion 	'',	count(*) from 		 ResAPortByRegion 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortByReinsurer 	'',	count(*) from 		 ResAPortByReinsurer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortByTreaty 	'',	count(*) from 		 ResAPortByTreaty 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortLFSByIntensity 	'',	count(*) from 		 ResAPortLFSByIntensity 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortOEP 	'',	count(*) from 		 ResAPortOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortOEPEx 	'',	count(*) from 		 ResAPortOEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortOEPTVaR 	'',	count(*) from 		 ResAPortOEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortOEPTVaREx 	'',	count(*) from 		 ResAPortOEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortReinstByLayer 	'',	count(*) from 		 ResAPortReinstByLayer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortReinstByReinsurer 	'',	count(*) from 		 ResAPortReinstByReinsurer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortReinstByTreaty 	'',	count(*) from 		 ResAPortReinstByTreaty 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortAEP 	'',	count(*) from 		 ResRPortAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortAEPEx 	'',	count(*) from 		 ResRPortAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortAEPTVaR 	'',	count(*) from 		 ResRPortAEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortAEPTVaREx 	'',	count(*) from 		 ResRPortAEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortByCountry 	'',	count(*) from 		 ResRPortByCountry 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortByCustomRgnAEP 	'',	count(*) from 		 ResRPortByCustomRgnAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortByDivision 	'',	count(*) from 		 ResRPortByDivision 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortByProducer 	'',	count(*) from 		 ResRPortByProducer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortByProgram 	'',	count(*) from 		 ResRPortByProgram 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortByRegion 	'',	count(*) from 		 ResRPortByRegion 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortByTreatyType 	'',	count(*) from 		 ResRPortByTreatyType 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortLFSByIntensity 	'',	count(*) from 		 ResRPortLFSByIntensity 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortOEP 	'',	count(*) from 		 ResRPortOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortOEPEx 	'',	count(*) from 		 ResRPortOEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortOEPTVaR 	'',	count(*) from 		 ResRPortOEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortOEPTVaREx 	'',	count(*) from 		 ResRPortOEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 SP_FILES 	'',	count(*) from 		 SP_FILES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccAEP 	'',	count(*) from 		 ResRAccAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccAEPEx 	'',	count(*) from 		 ResRAccAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccByLayer 	'',	count(*) from 		 ResRAccByLayer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccByTreaty 	'',	count(*) from 		 ResRAccByTreaty 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccOEP 	'',	count(*) from 		 ResRAccOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccOEPEx 	'',	count(*) from 		 ResRAccOEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyAEP 	'',	count(*) from 		 ResRTrtyAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyAEPEx 	'',	count(*) from 		 ResRTrtyAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyByCustomRgnAEP 	'',	count(*) from 		 ResRTrtyByCustomRgnAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyByLayer 	'',	count(*) from 		 ResRTrtyByLayer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyByRegion 	'',	count(*) from 		 ResRTrtyByRegion 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyByReinstatement 	'',	count(*) from 		 ResRTrtyByReinstatement 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyOEP 	'',	count(*) from 		 ResRTrtyOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyOEPEx 	'',	count(*) from 		 ResRTrtyOEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByCountryData	'',	count(*) from 		ELTByCountryData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByLayerData	'',	count(*) from 		ELTByLayerData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByPolicyData	'',	count(*) from 		ELTByPolicyData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByRegionData	'',	count(*) from 		ELTByRegionData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTBySiteData	'',	count(*) from 		ELTBySiteData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTBySubRegionData	'',	count(*) from 		ELTBySubRegionData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTPortData	'',	count(*) from 		ELTPortData	' execute (@sql);
		
		set @sql='insert '+@tablename+'	select ''	DMGRES 	'',	count(*) from '+@irDBName+'..'+' 		DMGRES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 DMGRESB 	'',	count(*) from '+@irDBName+'..'+' 		 DMGRESB 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ExpPolA 	'',	count(*) from '+@irDBName+'..'+' 		 ExpPolA 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ExpRes 	'',	count(*) from '+@irDBName+'..'+' 		 ExpRes 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ExpResB 	'',	count(*) from '+@irDBName+'..'+' 		 ExpResB 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 Progrs_a 	'',	count(*) from '+@irDBName+'..'+' 		 Progrs_a 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 Progrs_p 	'',	count(*) from '+@irDBName+'..'+' 		 Progrs_p 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 TrtyRec 	'',	count(*) from '+@irDBName+'..'+' 		 TrtyRec 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 RTRORES 	'',	count(*) from '+@irDBName+'..'+' 		 RTRORES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 RTRORESA 	'',	count(*) from '+@irDBName+'..'+' 		 RTRORESA 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 RTRORESD 	'',	count(*) from '+@irDBName+'..'+' 		 RTRORESD 	' execute (@sql);
	end
	
	if (@TestNum=14)
	begin
		set @sql='insert '+@tablename+'	select ''	 ResAPortAEP 	'',	count(*) from 		 ResAPortAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortAEPEx 	'',	count(*) from 		 ResAPortAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortAEPTVaR 	'',	count(*) from 		 ResAPortAEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortAEPTVaREx 	'',	count(*) from 		 ResAPortAEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortByCountry 	'',	count(*) from 		 ResAPortByCountry 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortByCustomRgnNetPreCatOEP 	'',	count(*) from 		 ResAPortByCustomRgnNetPreCatOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortByCustomRgnRecByTreatyOEP 	'',	count(*) from 		 ResAPortByCustomRgnRecByTreatyOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortByLayer 	'',	count(*) from 		 ResAPortByLayer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortByPortfolio 	'',	count(*) from 		 ResAPortByPortfolio 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortByRegion 	'',	count(*) from 		 ResAPortByRegion 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortByReinsurer 	'',	count(*) from 		 ResAPortByReinsurer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortByTreaty 	'',	count(*) from 		 ResAPortByTreaty 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortLFSByIntensity 	'',	count(*) from 		 ResAPortLFSByIntensity 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortOEP 	'',	count(*) from 		 ResAPortOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortOEPEx 	'',	count(*) from 		 ResAPortOEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortOEPTVaR 	'',	count(*) from 		 ResAPortOEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortOEPTVaREx 	'',	count(*) from 		 ResAPortOEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortReinstByLayer 	'',	count(*) from 		 ResAPortReinstByLayer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortReinstByReinsurer 	'',	count(*) from 		 ResAPortReinstByReinsurer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResAPortReinstByTreaty 	'',	count(*) from 		 ResAPortReinstByTreaty 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortAEP 	'',	count(*) from 		 ResRPortAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortAEPEx 	'',	count(*) from 		 ResRPortAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortAEPTVaR 	'',	count(*) from 		 ResRPortAEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortAEPTVaREx 	'',	count(*) from 		 ResRPortAEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortByCountry 	'',	count(*) from 		 ResRPortByCountry 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortByCustomRgnAEP 	'',	count(*) from 		 ResRPortByCustomRgnAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortByDivision 	'',	count(*) from 		 ResRPortByDivision 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortByProducer 	'',	count(*) from 		 ResRPortByProducer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortByProgram 	'',	count(*) from 		 ResRPortByProgram 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortByRegion 	'',	count(*) from 		 ResRPortByRegion 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortByTreatyType 	'',	count(*) from 		 ResRPortByTreatyType 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortLFSByIntensity 	'',	count(*) from 		 ResRPortLFSByIntensity 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortOEP 	'',	count(*) from 		 ResRPortOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortOEPEx 	'',	count(*) from 		 ResRPortOEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortOEPTVaR 	'',	count(*) from 		 ResRPortOEPTVaR 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRPortOEPTVaREx 	'',	count(*) from 		 ResRPortOEPTVaREx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 SP_FILES 	'',	count(*) from 		 SP_FILES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccAEP 	'',	count(*) from 		 ResRAccAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccAEPEx 	'',	count(*) from 		 ResRAccAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccByLayer 	'',	count(*) from 		 ResRAccByLayer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccByTreaty 	'',	count(*) from 		 ResRAccByTreaty 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccOEP 	'',	count(*) from 		 ResRAccOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRAccOEPEx 	'',	count(*) from 		 ResRAccOEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyAEP 	'',	count(*) from 		 ResRTrtyAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyAEPEx 	'',	count(*) from 		 ResRTrtyAEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyByCustomRgnAEP 	'',	count(*) from 		 ResRTrtyByCustomRgnAEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyByLayer 	'',	count(*) from 		 ResRTrtyByLayer 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyByRegion 	'',	count(*) from 		 ResRTrtyByRegion 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyByReinstatement 	'',	count(*) from 		 ResRTrtyByReinstatement 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyOEP 	'',	count(*) from 		 ResRTrtyOEP 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ResRTrtyOEPEx 	'',	count(*) from 		 ResRTrtyOEPEx 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByCountryData	'',	count(*) from 		ELTByCountryData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByLayerData	'',	count(*) from 		ELTByLayerData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByPolicyData	'',	count(*) from 		ELTByPolicyData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTByRegionData	'',	count(*) from 		ELTByRegionData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTBySiteData	'',	count(*) from 		ELTBySiteData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTBySubRegionData	'',	count(*) from 		ELTBySubRegionData	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	ELTPortData	'',	count(*) from 		ELTPortData	' execute (@sql);
									
		set @sql='insert '+@tablename+'	select ''	 DMGRES 	'',	count(*) from '+@irDBName+'..'+' 		 DMGRES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 DMGRESB 	'',	count(*) from '+@irDBName+'..'+' 		 DMGRESB 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ExpPolA 	'',	count(*) from '+@irDBName+'..'+' 		 ExpPolA 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ExpRes 	'',	count(*) from '+@irDBName+'..'+' 		 ExpRes 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 ExpResB 	'',	count(*) from '+@irDBName+'..'+' 		 ExpResB 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 Progrs_a 	'',	count(*) from '+@irDBName+'..'+' 		 Progrs_a 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 Progrs_p 	'',	count(*) from '+@irDBName+'..'+' 		 Progrs_p 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 TrtyRec 	'',	count(*) from '+@irDBName+'..'+' 		 TrtyRec 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 RTRORES 	'',	count(*) from '+@irDBName+'..'+' 		 RTRORES 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 RTRORESA 	'',	count(*) from '+@irDBName+'..'+' 		 RTRORESA 	' execute (@sql);
		set @sql='insert '+@tablename+'	select ''	 RTRORESD 	'',	count(*) from '+@irDBName+'..'+' 		 RTRORESD 	' execute (@sql);
	end
				
	set @sql='select * from '+@tablename; execute (@sql);
END	
/*
execute absp_CompareTestStats @tablename='MyTest1', @TestNum=3
execute absp_CompareTestStats @tablename='MyTest2', @TestNum=3
execute absp_CompareTestStats @tablename='test', @TestNum=0, @CompareTable1='MyTest1', @CompareTable2='MyTest2'

select * from tablelist 
*/
