
if EXISTS(select * FROM sysobjects WHERE id = object_id(N'absp_WbuFloodResultsCopy') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   DROP PROCEDURE absp_WbuFloodResultsCopy;
end
 GO
create procedure absp_WbuFloodResultsCopy @exposureKey int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure copies data from ResPPortFloodRiskByLocation into ResPPortLocInfo.
See mantis defect 0011104: WBU: Need to add a procedure to copy certain fields from ResPPortBySiteFlood to the WBU hazard table

Returns:	nothing.

====================================================================================================
</pre>
</font>
##BD_END

##PD  @exposureKey ^^  The ExposureKey to copy.

*/
AS
begin

 insert into ResPPortLocInfo (Pport_Key, AnlCfg_Key, ExposureKey, AccountKey, SiteKey, StructureKey, AccountNumber, SiteNumber, StructureNumber, 
	Name, Value, Units)
(select Pport_Key, 0, ExposureKey, AccountKey, SiteKey, StructureKey, AccountNumber, SiteNumber, StructureNumber,
	'IsInsideFloodZone', IsInsideFloodZone, ''
 from ResPPortFloodRiskByLocation where ExposureKey = @exposureKey);

 insert into ResPPortLocInfo (Pport_Key, AnlCfg_Key, ExposureKey, AccountKey, SiteKey, StructureKey, AccountNumber, SiteNumber, StructureNumber, 
	Name, Value, Units)
(select Pport_Key, 0, ExposureKey, AccountKey, SiteKey, StructureKey, AccountNumber, SiteNumber, StructureNumber,
	'HUC12', HUC12, ''
 from ResPPortFloodRiskByLocation where ExposureKey = @exposureKey);

 insert into ResPPortLocInfo (Pport_Key, AnlCfg_Key, ExposureKey, AccountKey, SiteKey, StructureKey, AccountNumber, SiteNumber, StructureNumber, 
	Name, Value, Units)
(select Pport_Key, 0, ExposureKey, AccountKey, SiteKey, StructureKey, AccountNumber, SiteNumber, StructureNumber,
	'WSESource', WSESource, ''
 from ResPPortFloodRiskByLocation where ExposureKey = @exposureKey);

 insert into ResPPortLocInfo (Pport_Key, AnlCfg_Key, ExposureKey, AccountKey, SiteKey, StructureKey, AccountNumber, SiteNumber, StructureNumber, 
	Name, Value, Units)
(select Pport_Key, 0, ExposureKey, AccountKey, SiteKey, StructureKey, AccountNumber, SiteNumber, StructureNumber,
	'CoastalZone', CoastalZone, ''
 from ResPPortFloodRiskByLocation where ExposureKey = @exposureKey);

 insert into ResPPortLocInfo (Pport_Key, AnlCfg_Key, ExposureKey, AccountKey, SiteKey, StructureKey, AccountNumber, SiteNumber, StructureNumber, 
	Name, Value, Units)
(select Pport_Key, 0, ExposureKey, AccountKey, SiteKey, StructureKey, AccountNumber, SiteNumber, StructureNumber,
	'DistanceToZone ', DistanceToZone , DistanceUnits
 from ResPPortFloodRiskByLocation where ExposureKey = @exposureKey);

 insert into ResPPortLocInfo (Pport_Key, AnlCfg_Key, ExposureKey, AccountKey, SiteKey, StructureKey, AccountNumber, SiteNumber, StructureNumber, 
	Name, Value, Units)
(select Pport_Key, 0, ExposureKey, AccountKey, SiteKey, StructureKey, AccountNumber, SiteNumber, StructureNumber,
	'WSE', WSE, ElevationUnits
 from ResPPortFloodRiskByLocation where ExposureKey = @exposureKey);

 insert into ResPPortLocInfo (Pport_Key, AnlCfg_Key, ExposureKey, AccountKey, SiteKey, StructureKey, AccountNumber, SiteNumber, StructureNumber, 
	Name, Value, Units)
(select Pport_Key, 0, ExposureKey, AccountKey, SiteKey, StructureKey, AccountNumber, SiteNumber, StructureNumber,
	'WSEActual', WSEActual, ElevationUnits
 from ResPPortFloodRiskByLocation where ExposureKey = @exposureKey);

 insert into ResPPortLocInfo (Pport_Key, AnlCfg_Key, ExposureKey, AccountKey, SiteKey, StructureKey, AccountNumber, SiteNumber, StructureNumber, 
	Name, Value, Units)
(select Pport_Key, 0, ExposureKey, AccountKey, SiteKey, StructureKey, AccountNumber, SiteNumber, StructureNumber,
	'Floor1Elevation', Floor1Elevation, ''
 from ResPPortFloodRiskByLocation where ExposureKey = @exposureKey);


 end








