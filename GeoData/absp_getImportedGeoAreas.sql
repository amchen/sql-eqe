if exists(select * from SYSOBJECTS where ID = object_id(N'absp_getImportedGeoAreas') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_getImportedGeoAreas
end
go

create procedure absp_getImportedGeoAreas @nodeKey int = 0 ,@nodeType int = 27  /*program*/
AS
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return a single resultset containing a list of regions for the countries
belonging to the exposure key(s) for a given program or for all pports and rports of a given aport.


Returns:       A single resultset containing a list of region names and id.

====================================================================================================
</pre>
</font>
##BD_END

##PD nodeKey^^ The key of the program or aport node
##PD nodeType^^ The node type (1 or 27)

##RS  NAME 	^^  The region name
##RS  RRGNGRP_ID 	^^  The region goup id

*/
begin
	set nocount on

	--	declare temporary table RRGNGRPS_TMP
	declare @inList varchar(max)
	declare @sql varchar(max)
	--IF object_id('tempdb..#RRGNGRPS_TMP', 'U') is not null
	--drop table #RRGNGRPS_TMP

	create table #RRGNGRPS_TMP
	(
		RRGNGRP_ID int   null,
		NAME char(50)   COLLATE SQL_Latin1_General_CP1_CI_AS  null
	)

	set @inList = ''

	-- node type = 27 - program
	if(@nodeKey > 0 and @nodeType = 27)
	begin
		set @sql = 'select distinct ExposureKey from ExposureMap where ParentKey = ' +
				 '(select Prog_Key from PROGINFO where prog_key = '+rtrim(ltrim(str(@nodeKey))) +
				 ') and ParentType = ' + rtrim(ltrim(str(@nodeType)))
		execute  absp_Util_GenInList @inList out,@sql,'N'
		set @sql = 'select distinct CountryKey from ExposureValue where ExposureKey ' + @inList
		execute absp_Util_GenInList @inList out,@sql, 'N'
		set @sql = 'select distinct COUNTRY_ID from ExpRegns where countryKey ' + @inList
		execute  absp_Util_GenInList @inList out , @sql, 'S'
		set @sql = 'select distinct RRGN_KEY from RRGNLIST where COUNTRY_ID '+ @inList
		execute absp_Util_GenInList @inList out, @sql, 'N'
		set @sql = 'select distinct RRGNGRP_ID from RREGIONS where RRGN_KEY '+ @inList
		execute absp_Util_GenInList @inList out, @sql,'N'
		set @sql = ' insert into #RRGNGRPS_TMP SELECT RRGNGRP_ID, NAME FROM RRGNGRPS WHERE RRGNGRP_ID '+ @inList+' order by NAME asc'
		execute(@sql)
		select   NAME as NAME, RRGNGRP_ID as RRGNGRP_ID from #RRGNGRPS_TMP
	end
	else
	-- node type = 1 - aportfolio
	begin
		if(@nodeKey > 0 and @nodeType = 1)
		begin
			set @sql = 'select ExposureKey from ExposureMap join ' + ' APORTMAP on ExposureMap.ParentKey = APORTMAP.child_key '+
					'where aport_key = ' + rtrim(ltrim(str(@nodeKey))) + ' and APORTMAP.child_type = 2 ' +
					'union ' +
					'select ExposureKey from ExposureMap join proginfo ' + 'on ExposureMap.ParentKey = proginfo.prog_key ' +
                    'join RPORTMAP on RPORTMAP.child_key = progInfo.prog_key ' +
					'join APORTMAP on RPORTMAP.rport_key = APORTMAP.child_key ' +
					'where aport_key = '+rtrim(ltrim(str(@nodeKey))) +
					' and APORTMAP.child_type = 23 and ExposureMap.parentType=27 and RPORTMAP.Child_type=27'
			--print @sql
			execute  absp_Util_GenInList @inList out,@sql,'N'
			set @sql = 'select distinct CountryKey from ExposureValue where ExposureKey ' + @inList
			execute absp_Util_GenInList @inList out,@sql, 'N'
			set @sql = 'select distinct COUNTRY_ID from ExpRegns where countryKey ' + @inList
			execute  absp_Util_GenInList @inList out , @sql, 'S'
			set @sql = 'select distinct RRGN_KEY from RRGNLIST where COUNTRY_ID '+ @inList
			execute absp_Util_GenInList @inList out, @sql,'N'
			set @sql = 'select distinct RRGNGRP_ID from RREGIONS where RRGN_KEY '+ @inList
			execute absp_Util_GenInList @inList out, @sql, 'N'
			set @sql = ' insert into #RRGNGRPS_TMP select RRGNGRP_ID, NAME from RRGNGRPS where RRGNGRP_ID ' + @inList+' order by NAME asc'
			execute(@sql)
			select   NAME AS NAME, RRGNGRP_ID as RRGNGRP_ID from #RRGNGRPS_TMP
		end
	end
end