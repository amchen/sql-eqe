if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Dev_WBU_Sim') and objectproperty(ID,N'isprocedure') = 1)
begin
 drop procedure absp_Dev_WBU_Sim
end
go

create procedure absp_Dev_WBU_Sim
	@slqServerInstanceName varchar(255),
	@edbName varchar(255), 
	@folderName varchar(255), 
	@portfolioName varchar(255), 
	@latitude float, 
	@longitude float,
	@numStructures int = 0
as
/*
irvine testing only

note: @numStructures may be set greater than 0 to have multiple structures created with each 
      having latitute 0.5 and longitude -0.5 added for each.
      In this case, the Batch options set StructureKey = 0.

-- exec absp_Dev_WBU_Sim 'KZIMMERMANDT02\SQLSERVER2008R2', '_RQE_Default', 'AccuRUSiAutomationFolder', 'AutoPof', 33.716672, -117.786109, 0
-- exec absp_Dev_WBU_Sim '764IRV5496DT01\SQLSERVER2008R2', '_RQE_Default', 'AccuRUSiAutomationFolder', 'AutoPof', 33.716672, -117.786109, 0
-- 
*/
begin
declare @connectStr varchar(500);
declare	@serverSharedFolder varchar(255);
declare @sql varchar(250);
declare @dbName varchar(250);
declare @pportType int;
declare @folderKey int;
declare @pportKey int;
declare @exposureKey int;
declare @accountKey int;
declare @siteKey int;
declare @structureKey int;
declare @now varchar(50);
declare @CfRefKey int;
declare @batchJobKey int;
declare @batchJobKeyAnalysis int;
declare @longName varchar(250)
declare @batchJobStepKey int;

set @pportType = 2;
set @dbName = @edbName;

set @serverSharedFolder = '"c:\\RQEShared"';
select @connectStr = 'Data Source=@SQLINST;Initial Catalog=@EDBNAME;User Id=wce;Password=wcepwd;';

select Replace(@connectStr, '@SQLINST', @slqServerInstanceName);
select Replace(@connectStr, '@EDBNAME', @edbName);

select @now = convert(varchar, getdate(), 121)

select @longName = @portfolioName + @now + '_';

-- create me a pport
insert into PprtInfo
  (LongName, Status, Create_Dat, Create_By, Group_Key)
values
  (@longName, 'ACTIVE', '20130521092746', 1, 1);
  
select @pportKey = @@IDENTITY;

update PprtInfo set LongName = @longName + CAST(@pportKey as CHAR(6)) where Pport_Key = @pportKey;


-- add it to my tree
select @folderKey = Folder_key from FldrInfo where LongName = @folderName;
insert into FldrMap values (@folderKey, @pportKey, @pportType);

-- create me an exposure
insert into ExposureInfo
  (Status, ImportStatus, GeocodeStatus, ReportStatus, GroupKey, Attrib, CreateDate, ModifyDate, CreatedBy, ModifiedBy)
values
  ('Imported', 'Completed', 'Completed', 'Completed', 1, 0, '20130521093131', NULL, 1, 1);

select @exposureKey = @@IDENTITY;

-- fake out a source for it
insert into ExposureFile
  (ExposureKey, SourceID, SourceType, OriginalSourceName, SourceName, SourceCategory, TableName, Status, ReadyForUse, Delimiter, StartHeaderRow, EndHeaderRow, FirstDataRow)
values
  (@exposureKey, 1, 'X', 'External ICMS', 'WBU Mode', '', 'User_Data_1', 'Submitted', 'Y', 'tab', 1, 1, 2);

-- fake out templates
insert into ExposureTemplate (ExposureKey, TemplateName, TemplateType, TemplateXml, CreatedVersion)
  select @exposureKey, TemplateName, TemplateType, TemplateXml, TemplateVersion from TemplateInfo where TemplateInfoKey in(9, 6, 13)

-- add that exposure to my pport
insert into ExposureMap 
  (ExposureKey, ParentKey, ParentType)
values
  (@exposureKey, @pportKey, @pportType);
  
-- so create an Account
set @accountKey = 1;
insert into Account
  (ExposureKey, AccountKey, AccountNumber, AccountName, Insured, Producer, Company, Branch, Division, UserData1, UserData2, UserData3, FinancialModelType, PriceOfGas, PriceOfOil, InputSourceID, InputSourceRowNum, IsValid, IsDeleted)
values
  (@exposureKey, @accountKey, 'AutoAcc-001', 'AutoAcct', '', '', '', '', '', '', '', '', 0, 0, 0, 1, 2, 1, 0);
  
-- now create a site
set @siteKey = 1;
insert into Site
  (ExposureKey, AccountKey, SiteKey, SiteNumber, SiteName, CurrencyCode, UserData1, UserData2, UserData3, InputSourceID, InputSourceRowNum, IsValid)
values
  (@exposureKey, @accountKey, @siteKey, 'SN001', 'AutoSite', 'USD', '', '', '', 1, 2, 1);
  
declare @countryKey int;
select @countryKey = CountryKey from Country where Iso_3 = 'USA'
	

-- Keep creating structures until @numStructures	
set @structureKey = 0;

declare @structureCount int

set @structureCount = @numStructures
if @structureCount = 0 set @structureCount = 1


while (@structureCount > 0)
	
begin	

		set @structureCount = @structureCount - 1
			
		-- Create a structure: country  = USA	
		set @structureKey = @structureKey + 1;
		insert into Structure
			(ExposureKey, AccountKey, SiteKey, StructureKey, StructureNumber, StructureName, CountryCode, 
			StreetAddress, City, AdminLevel1, AdminLevel2, AdminLevel3, Postcode, PostcodeAux, GeoAreaCode, 
			ThematicPostcode, Cresta, SubCresta, CrestaHighRes, CrestaLowRes, CrestaVintage, 
			Latitude, Longitude, YearBuilt, YearUpgraded, PercentComplete, NumStories, NumBuildings, 
			OccupancyTypeID, EQOccupancyTypeID, WSOccupancyTypeID, FLOccupancyTypeID, 
			StructureTypeID, EQStructureTypeID, WSStructureTypeID, FLStructureTypeID, 
			StructureModifierID, UserGeoData1, UserGeoData2, UserGeoData3, UserData1, UserData2, UserData3, PercentAssured, 
			Locator, FirstFloorElevation, HasBasement, PctStructureSprinklered, SprinklerContentPctVulnHigh, SprinklerContentPctVulnMedium, SprinklerContentPctVulnLow, 
			Salary, Headcount, Shift1Weight, Shift2Weight, Shift3Weight, Shift4Weight, 
			AssetCode, BoemBlock, PipelineEndingBlock, PipelineEndingLatitude, PipelineEndingLongitude, 
			GeocodeLevelID, GeocodeStatus, CountryKey, 
			RegionCode, DistanceToCoast, TerrainFeature1, TerrainFeature2, GroundElevation, 
			SoilType, SoilFactor, EQInfoQuality, WSInfoQuality, FLInfoQuality, 
			CellID, RiskTypeID, FireClass, PbndryComboKey, RegionKey, 
			CountryCodeStatus, StreetAddressStatus, StreetGeocoderID, 
			CityStatus, AdminLevel1Status, AdminLevel2Status, AdminLevel3Status, PostcodeStatus, CrestaStatus, SubCrestaStatus, LatLonStatus, OccupancyTypeStatus, StructureTypeStatus, 
			YearBuiltStatus, YearUpgradedStatus, 
			NumStoriesStatus, NumBuildingsStatus, FirstFloorElevationStatus, 
			LocatorStatus, DistanceToCoastStatus, TerrainFeature1Status, TerrainFeature2Status, GroundElevationStatus, SoilStatus, CellIDStatus, 
			IsOffshore, HasFeatures, SiteCurrencyCode, 
			InputSourceID, InputSourceRowNum, IsValid, WcFieldsStatusId)
		values	
			(@exposureKey, @accountKey, @siteKey, @structureKey, 's-' + CAST(@structureKey as CHAR(6)), 'AutoStruct', 'USA',
			'',	'',	'',	'',	'',	'',	'',	'',
			'',	'',	'',	'',	'',	'',	 
			@latitude, @longitude,	'',	'',	100, 1,	1,			
			11013,	11013,	11013,	11013,				
			11003,	12019,	12019,	12019,				
			1,	'',	'',	'',	'',	'',	'' , 100,		
			'',	0,	0,	0,	0,	0,	0,							
			0,	0,	0,	0,	0,	0,		
			'',	'',	'',	0,	0,						
			0,	0,	@countryKey,			
			'',	0,	0,	0,	0,			
			'',	0,	0,	0,	0,				
			0,	9,	0,	0,	0,		
			'',	'',	0,					
			'',	'',	'',	'',	'', '',	'',	'',	'',	'',	
			'',	'',	
			'U', 'U', 'U',	
			'',	'',	'',	'',	'',	'',	 '',			
			0,	0,	'USD',		
			1,	2,	1,	0);

		set @latitude = @latitude + 0.5
		set @longitude = @longitude - 0.5

		-- now we need some coverages
		-- set @structureKey = 1;
		--insert into StructureCoverage
		--  (ExposureKey, AccountKey, SiteKey, StructureKey, PerilID, CoverageID, Value, DamageFactor, CoverageQuality, InputSourceID, InputSourceRowNum, IsValid)
		--values
		--  (@exposureKey, @accountKey, @siteKey, @structureKey, 1, 1407, 1000000, 1, 50, 1, 2, 1);

		insert into StructureCoverage
		  (ExposureKey, AccountKey, SiteKey, StructureKey, PerilID, CoverageID, Value, DamageFactor, CoverageQuality, InputSourceID, InputSourceRowNum, IsValid)
		values  
		  (@exposureKey, @accountKey, @siteKey, @structureKey, 2, 1407, 1000000, 1, 50, 1, 2, 1);

		--set @structureKey = @structureKey + 1;
		--insert into StructureCoverage
		--  (ExposureKey, AccountKey, SiteKey, StructureKey, PerilID, CoverageID, Value, DamageFactor, CoverageQuality, InputSourceID, InputSourceRowNum, IsValid)
		--values
		--  (@exposureKey, @accountKey, @siteKey, @structureKey, 1, 1407, 1000000, 1, 54, 1, 3, 1);
		  
		--insert into StructureCoverage
		--  (ExposureKey, AccountKey, SiteKey, StructureKey, PerilID, CoverageID, Value, DamageFactor, CoverageQuality, InputSourceID, InputSourceRowNum, IsValid)
		--values
		--  (@exposureKey, @accountKey, @siteKey, @structureKey, 2, 1407, 1000000, 1, 50, 1, 3, 1);
		  
		exec absp_ExposureCountUpdate @exposureKey;
		  
		select @CfRefKey = CF_Ref_KEY from CFldrInfo where LongName = @dbName

end

-- 0008049: Single Site geocoding: Part 1 of 2: Ensure Single site works direct to tables with no merge steps needed
--  Put in the PLAN_JOB step but mark is as S for success.
--  Then plug in the next step with whatever single-structure and single-site parameters you need to geocode some existing data.


-- Create a Plan Job, but marked success because we will manually create the Plan

declare @batchJobStatus varchar(2);
declare @StepStatus varchar(2);

select @batchJobStatus = 'X';		-- 'W' for wait, 'PS' for Paused, 'S' for Success, 'X' placeHolder for neutral - do nothing

print '@folderKey=' + cast(@folderKey as char) + '@pportKey=' + cast(@pportKey as char) + '@exposurekey' + cast(@exposurekey as char) + '@dbName=' + @dbName + '  @CfRefKey=' + cast(@CfRefKey as char)

insert into BatchJob (
  JobTypeID, UserKey, SessionID, NodeType, DBRefKey,  FolderKey, AportKey, PportKey,	ExposureKey, AccountKey, PolicyKey, SiteKey, RportKey, ProgramKey, 
  
  CaseKey, AnalysisRunKey, DependencyKeyList, CriticalJob, JobOrder, DBName, EmailUser, SubmitDate,  StartDate, FinishDate, TotalExecutionTime, TotalDurationTime, 
  
  JobOptions, 
  
  Status, RdbInfoKey
)
values(
  1,			1,			4,		2,		@CfRefKey,  0,		0,			@pportKey,	@exposureKey, 0,			0,			0,		0,		0,			
  0,		0,				'0',				'N',		0,		  @dbName,  'N',	'20130729172412', '',	'',			0,						0,  
  
  '<JobOptions jobKey="@batchJobKey" type="Geocode" exposureKey="' + rtrim(cast(@exposurekey as char)) + 
  '" nodeType="@pportType" nodeKey="' + rtrim(cast(@pportKey as char)) +'">' +
  '<ImportJobOptions numErrorsToStop="100000" numRowsToProcess="0" serverSharedFolder="" doGeocode="false">' +
  '<EngineOptions name="" logKey="0" priorityCode=""><GenericEngineOptions><AnalysisDir></AnalysisDir>' +
  '<DatabaseConnectionInfo irConnStr="" primaryConnStr=""/></GenericEngineOptions></EngineOptions></ImportJobOptions></JobOptions>', 
  
  @batchJobStatus, 0
)
;

select @batchJobKey = @@Identity;

--print '@batchJobKey=' + cast(@batchJobKey as char)

-- set locking attribute to simulate getting an "analysis lock" before setting the first geocoder job step to success
-- the job processor will eventually release the "lock" by resetting the attribute bit
exec absp_InfoTableAttrib_Set 2, @pportKey, 'BATCH_IN_PROGRESS', 1

update BatchJob set JobOptions = replace(JobOptions, '@batchJobKey', @batchJobKey) where BatchJobKey = @batchJobKey;
update BatchJob set JobOptions = replace(JobOptions, '@pportType', @pportType) where BatchJobKey = @batchJobKey;


-- Create a Plan BatchJobStep record for the Geocoder BatchJob, Marked as Successful
select @StepStatus = 'S';			-- 'W' for Wait, 'S' for Success

insert into BatchJobStep (
	BatchJobKey, PlanSequenceID, SequenceID, StepWeight, EngineName,  Priority, AnalysisConfigKey, Logkey, StartDate, FinishDate, LastResponseTime, 

	ExecutionTime, EngineGroupID, EnginePid, HostName, HostPort, Status, ErrorMessage, EngineArgs
)
values (
	@batchJobKey, 1,				1,			0,		'PLAN_JOB',		'N',	0,					0,			'',		'',			'', 

	0,				0,				0,		'',			0,		@StepStatus,		'',			''
)
;


-- Create the JobStep to execute the Single Site Geocode marked as Waiting
select @StepStatus = 'W';			-- 'W' for Wait, 'S' for Success


insert into BatchJobStep (
	BatchJobKey, PlanSequenceID, SequenceID, StepWeight, EngineName,				Priority, AnalysisConfigKey, Logkey, StartDate, FinishDate, LastResponseTime, 

	ExecutionTime, EngineGroupID, EnginePid, HostName, HostPort, Status,			ErrorMessage, 
	
	EngineArgs
)
values (
	@batchJobKey, 1,				2,			0,		'GeocodeLauncher32',		'N',		0,					0,			'',		'',			'', 

	0,				0,				0,		 '',		0,		@StepStatus,		'',			
	
	'<JobOptions jobKey="67" type="Import" exposureKey="@ExposureKey" nodeType="@pportType" nodeKey="@pportKey">' +
	'<ImportJobOptions numErrorsToStop="100000" numRowsToProcess="0" serverSharedFolder=@serverSharedFolder doGeocode="false">' +
	'<EngineOptions name="GeocodeLauncher32" useIrDbFlag="false" deleteLogs="false" logKey="-1" priorityCode="N">' +
	'<GenericEngineOptions><AnalysisDir></AnalysisDir><DatabaseConnectionInfo irConnStr="" primaryConnStr="@connectStr"/>' +
	'</GenericEngineOptions></EngineOptions>' +
	'<GeocodeEngineOptions summaryTableName="GeocodeSummary" progressTableName="GeocodeProgress" logLevel="0" countryCode="USA" ' +
	'function="SingleSiteGeocode" geocoderType="InternalGeocoder">' +
	'<InternalGeocoderOptions includeStreet="false"><StreetGeocodeOptions type="MapMarker">' +
	'<MapMarkerOptions takeFirstMatchOnMultiple="false" requireExactMatchHouseNumber="true" requireExactMatchStreet="false" requireExactMatchZip="false"/>' +
	'</StreetGeocodeOptions><StructureFactorOptions ' +
	'siteCoverDestinationTableName="StructureCoverage" siteCoverSourceTableName="StructureCoverage" structureFeatureTableName="StructureFeature"/>' +
	'</InternalGeocoderOptions><SingleSiteGeocodeOptions structureKey="@StructureKey" />' +
	'</GeocodeEngineOptions></ImportJobOptions></JobOptions>'	
)
;

select @batchJobStepKey = @@IDENTITY;

if @numStructures > 0 set @StructureKey = 0

update BatchJobStep set EngineArgs = replace(EngineArgs, '@ExposureKey', @ExposureKey) where BatchJobKey = @batchJobKey and batchJobStepKey = @batchJobStepKey;
update BatchJobStep set EngineArgs = replace(EngineArgs, '@pportType', @pportType) where BatchJobKey = @batchJobKey and batchJobStepKey = @batchJobStepKey;
update BatchJobStep set EngineArgs = replace(EngineArgs, '@pportKey', @pportKey) where BatchJobKey = @batchJobKey and batchJobStepKey = @batchJobStepKey;
update BatchJobStep set EngineArgs = replace(EngineArgs, '@serverSharedFolder', @serverSharedFolder) where BatchJobKey = @batchJobKey and batchJobStepKey = @batchJobStepKey;
update BatchJobStep set EngineArgs = replace(EngineArgs, '@connectStr', @connectStr) where BatchJobKey = @batchJobKey and batchJobStepKey = @batchJobStepKey;
update BatchJobStep set EngineArgs = replace(EngineArgs, '@StructureKey', @StructureKey) where BatchJobKey = @batchJobKey and batchJobStepKey = @batchJobStepKey;

-- Create a paused BatchJob for the Analysis
--/*

insert into BatchJob (
  JobTypeID, UserKey, SessionID, NodeType, DBRefKey,  FolderKey, AportKey, PportKey, ExposureKey, 
  AccountKey, PolicyKey, SiteKey, RportKey, ProgramKey, CaseKey, AnalysisRunKey, 
  DependencyKeyList, CriticalJob, JobOrder, DBName, EmailUser, SubmitDate,  StartDate, FinishDate, TotalExecutionTime, TotalDurationTime, 
  JobOptions, Status, RdbInfoKey
)
values(
  0,  1,  4,  2,  @CfRefKey,  0,  0,  @pportKey, @exposureKey, 
  0,  0,  0,  0,  0,  0,  0,  
  '' + @batchJobKey+ '',  'N',  0,  @dbName,  'N', '20130729172412', '',  '',  0,  0,  
  '<?xml version="1.0"?><AnalysisTemplate><ReportSelection><ReportSelectionByNodeType applicableNodeType="Accumulation Portfolio"><SelectedReports><SelectedReport engineCallID="1000" reportMappingKey="10001" templateReportName="by Overall" reportType="4"></SelectedReport><SelectedReport engineCallID="1000" reportMappingKey="10005" templateReportName="by Country" reportType="3"></SelectedReport><SelectedReport engineCallID="1000" reportMappingKey="10007" templateReportName="by Portfolio" reportType="3"></SelectedReport><SelectedReport engineCallID="1000" reportMappingKey="10017" templateReportName="by Reinsurance/Retrocession by Reinsurer" reportType="3"></SelectedReport><SelectedReport engineCallID="1000" reportMappingKey="10019" templateReportName="by Reinsurance/Retrocession by Treaty" reportType="3"></SelectedReport><SelectedReport engineCallID="1000" reportMappingKey="10021" templateReportName="by Reinsurance/Retrocession by Layer" reportType="3"></SelectedReport><SelectedReport engineCallID="1000" reportMappingKey="10023" templateReportName="by Reinstatements by Reinsurer" reportType="3"></SelectedReport><SelectedReport engineCallID="1000" reportMappingKey="10025" templateReportName="by Reinstatements by Treaty" reportType="3"></SelectedReport><SelectedReport engineCallID="1000" reportMappingKey="10027" templateReportName="by Reinstatements by Layer" reportType="3"></SelectedReport></SelectedReports></ReportSelectionByNodeType><ReportSelectionByNodeType applicableNodeType="Primary Portfolio"><SelectedReports><SelectedReport engineCallID="2000" reportMappingKey="11001" templateReportName="by Overall" reportType="4"></SelectedReport><SelectedReport engineCallID="2000" reportMappingKey="11005" templateReportName="by Country" reportType="3"></SelectedReport><SelectedReport engineCallID="2000" reportMappingKey="11045" templateReportName="by US Landfall Series" reportType="3"></SelectedReport></SelectedReports></ReportSelectionByNodeType><ReportSelectionByNodeType applicableNodeType="Primary Account"><SelectedReports><SelectedReport engineCallID="4000" reportMappingKey="12001" templateReportName="by Overall" reportType="4"></SelectedReport></SelectedReports></ReportSelectionByNodeType><ReportSelectionByNodeType applicableNodeType="Primary Site"><SelectedReports><SelectedReport engineCallID="9000" reportMappingKey="13001" templateReportName="by Overall" reportType="4"></SelectedReport><SelectedReport engineCallID="9000" reportMappingKey="13003" templateReportName="by Coverage" reportType="3"></SelectedReport><SelectedReport engineCallID="9000" reportMappingKey="13005" templateReportName="by Structure" reportType="3"></SelectedReport></SelectedReports></ReportSelectionByNodeType><ReportSelectionByNodeType applicableNodeType="Reinsurance Portfolio"><SelectedReports><SelectedReport engineCallID="23000" reportMappingKey="16001" templateReportName="by Overall" reportType="4"></SelectedReport><SelectedReport engineCallID="23000" reportMappingKey="16005" templateReportName="by Country" reportType="3"></SelectedReport><SelectedReport engineCallID="23000" reportMappingKey="16012" templateReportName="by Division" reportType="3"></SelectedReport><SelectedReport engineCallID="23000" reportMappingKey="16014" templateReportName="by Producer" reportType="3"></SelectedReport><SelectedReport engineCallID="23000" reportMappingKey="16016" templateReportName="by Program" reportType="3"></SelectedReport><SelectedReport engineCallID="23000" reportMappingKey="16020" templateReportName="by Treaty Type" reportType="3"></SelectedReport><SelectedReport engineCallID="23000" reportMappingKey="16022" templateReportName="by US Landfall Series" reportType="3"></SelectedReport></SelectedReports></ReportSelectionByNodeType><ReportSelectionByNodeType applicableNodeType="Reinsurance Program"><SelectedReports><SelectedReport engineCallID="27000" reportMappingKey="17001" templateReportName="by Overall" reportType="4"></SelectedReport><SelectedReport engineCallID="27000" reportMappingKey="17006" templateReportName="by Layer" reportType="3"></SelectedReport><SelectedReport engineCallID="27000" reportMappingKey="17010" templateReportName="by Treaty Type" reportType="3"></SelectedReport></SelectedReports></ReportSelectionByNodeType><ReportSelectionByNodeType applicableNodeType="Reinsurance Treaty"><SelectedReports><SelectedReport engineCallID="30001" reportMappingKey="18001" templateReportName="by Overall" reportType="4"></SelectedReport><SelectedReport engineCallID="30001" reportMappingKey="18004" templateReportName="by Region" reportType="3"></SelectedReport><SelectedReport engineCallID="30001" reportMappingKey="18009" templateReportName="by Layer" reportType="3"></SelectedReport><SelectedReport engineCallID="30001" reportMappingKey="18012" templateReportName="by Reinstatements" reportType="3"></SelectedReport></SelectedReports></ReportSelectionByNodeType></ReportSelection><MetricSelection><Summary><ReturnPeriod>50</ReturnPeriod><ReturnPeriod>100</ReturnPeriod><ReturnPeriod>250</ReturnPeriod><ReturnPeriod>500</ReturnPeriod></Summary><ReturnPeriods><ReturnPeriod>2</ReturnPeriod><ReturnPeriod>3</ReturnPeriod><ReturnPeriod>5</ReturnPeriod><ReturnPeriod>7</ReturnPeriod><ReturnPeriod>10</ReturnPeriod><ReturnPeriod>11</ReturnPeriod><ReturnPeriod>13</ReturnPeriod><ReturnPeriod>14</ReturnPeriod><ReturnPeriod>17</ReturnPeriod><ReturnPeriod>20</ReturnPeriod><ReturnPeriod>25</ReturnPeriod><ReturnPeriod>33</ReturnPeriod><ReturnPeriod>50</ReturnPeriod><ReturnPeriod>100</ReturnPeriod><ReturnPeriod>111</ReturnPeriod><ReturnPeriod>125</ReturnPeriod><ReturnPeriod>143</ReturnPeriod><ReturnPeriod>167</ReturnPeriod><ReturnPeriod>200</ReturnPeriod><ReturnPeriod>250</ReturnPeriod><ReturnPeriod>333</ReturnPeriod><ReturnPeriod>500</ReturnPeriod><ReturnPeriod>1000</ReturnPeriod></ReturnPeriods><ELTMetrics><ELTMetric MetricName="ELTMetric-1" MetricID="1" MetricValue="D"></ELTMetric><ELTMetric MetricName="ELTMetric-2" MetricID="2" MetricValue="G"></ELTMetric></ELTMetrics><YLTMetrics><YLTMetric MetricName="YLTMetric-1" MetricID="1" MetricValue="D"></YLTMetric><YLTMetric MetricName="YLTMetric-2" MetricID="2" MetricValue="G"></YLTMetric></YLTMetrics></MetricSelection><EventSelection><EventType>Stochastic</EventType><EventType>Historical and hypothetical</EventType></EventSelection><AnalysisOptions><DemandSurge>Off</DemandSurge><Frequency>Long Term</Frequency></AnalysisOptions></AnalysisTemplate>', 
  'X', 0
)
;
select @batchJobKeyAnalysis = @@Identity;

-- Create a Plan BatchJobStep record for the Analysis

insert into BatchJobStep (
BatchJobKey, PlanSequenceID, SequenceID, StepWeight, EngineName,  Priority, AnalysisConfigKey, Logkey, StartDate, FinishDate, LastResponseTime, ExecutionTime, EngineGroupID, EnginePid, HostName, HostPort, Status, ErrorMessage, EngineArgs
)
values (
@batchJobKeyAnalysis, 1,  1,  0,  'PLAN_JOB', 'N',  0,  0,  '', '', '', 0,  0,  0,  '', 0,  'W',  '', ''
)
;

-- new table
insert into BatchJobSettings values(@batchJobKey, 'Normal', 0, 0, 'N');
insert into BatchJobSettings values(@batchJobKeyAnalysis, 'Normal', 0, 0, 'N');

-- Wake up the sleeping Geocode batch

update Batchjob set status = 'R' where status = 'X' and batchjobkey = @batchJobKey;
update Batchjob set status = 'W' where status = 'X' and batchjobkey = @batchJobKeyAnalysis;



--*/

select @exposureKey as ExpousureKey, @batchJobKey as JobKeyGeo, @batchJobKeyAnalysis as JobKeyAnalysis;
end
