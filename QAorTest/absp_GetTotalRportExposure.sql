if exists(select * from sysobjects where id = object_id(N'absp_GetTotalRportExposure') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GetTotalRportExposure;
end
go

create procedure absp_GetTotalRportExposure @rportName char(120), @debugFlag int = 0
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    SQL2005
Purpose:

    This procedure creates two flat files containing the exposure report of the given rport based on
    areas and countries respectively and returns a single resultset containing the total TIV grouped on
    countries for all programs under the given rport.


Returns:	A single resultset containing the total TIV grouped on countries for all programs
                under the given rport.

====================================================================================================
</pre>
</font>
##BD_END

##PD  rport_name ^^  The name of the rport for which the exposure reports are to be generated.
##PD  debugFlag ^^  The debug flag.

##RS  COUNTRYKEY ^^  The country key .
##RS  LEV1_DATA ^^  The official post office designation for a state.
##RS  BLDG_TIV ^^  The Building TIV.
##RS  CONT_TIV ^^  The Contents TIV.
##RS  TIME_TIV ^^  The Time TIV.

*/

/*

	This procedure will calculate the total exposure for a given Reinsurance Portfolio.
	Then the procure will create a bar delimited file called "Total Exposure Report for <RPort Name>.txt"

*/

as
begin

	-- standard declares
	declare @me varchar(2000)	-- Procedure Name
	--declare @debug int			-- for messaging
	declare @msg varchar(4000)
	declare @sql varchar(max)	-- to handle sql type work

	-- put other variables here
	declare @rportKey int
	declare @filepath varchar(2000)
	declare @tmpExpTbl varchar(100)

	-- Declare TMPTREEMAP temp table
	-- We need this table to return resultset back to Java Server. execute immediate cannot return multiple rows.

	create table #TMP_PROG_LIST	(	PROG_KEY int)

	exec absp_Util_MakeCustomTmpTable
        @tmpExpTbl output,
        'TMP_EXP_TBL',
        'COUNTRYKEY	int,LEV1_DATA	char(2),BLDG_TIV	float(53),CONT_TIV	float(53),TIME_TIV	float(53)'

	-- initialize standard items
	set @me = 'absp_GetTotalRportExposure: '  -- set to my name Procedure Name
	set @msg = @me + 'starting'
	set @sql = ''


	-- intialize other variables here

	if @debugFlag > 0
	begin
		exec absp_messageEx @msg
		set @msg = ' called absp_GetTotalRportExposure for RPort = ' + @rportName
		exec absp_messageEx @msg
	end


	-- Get the path where the file will be be unloaded.
	exec absp_Util_GetWceDBDir @filepath output
	set @filepath = replace (@filepath, '/', '\\')
	set @filePath = ltrim(rtrim(@filepath)) + 'Exposure Report for ' + ltrim(rtrim(@rportName))
	exec absp_Util_createFolder @filepath
	set @filepath = ltrim(rtrim(@filepath)) + '\\By Area Exposure Report for ' + ltrim(rtrim(@rportName)) + '.txt';

	-- Get the rport_key for the given rport

	select @rportKey = RPORT_KEY  from RPRTINFO where lONGNAME = @rportName;

	-- Now get the list of all programs under this rport

	set @sql = 'insert into #TMP_PROG_LIST
					select distinct CHILD_KEY from RPORTMAP where (CHILD_TYPE = 7 or CHILD_TYPE = 27) and RPORT_KEY = ' + str(@rportKey);

	execute(@sql)


	-- Now unload the data into a file with the country name and state based on countrykey and lev1_data

	if (@debugFlag > 0)
	begin
		set @sql = 'unload
						select distinct trim(COUNTRY), trim(STATE), BLDG_TIV, CONT_TIV, TIME_TIV from #TMP_EXP_TBL t1, COUNTRY t2, STATEL t3
						where t1.COUNTRYKEY = t2.COUNTRYKEY
						and t3.COUNTRY_ID = t2.COUNTRY_ID
						and t1.LEV1_DATA = t3.STATE_2

					to ''' + @filepath + ''' delimited by ''|'' format ascii quotes off'
		exec absp_MessageEx @sql
	end
	set @sql = 'select distinct ltrim(rtrim(COUNTRY)), ltrim(rtrim(STATE)), BLDG_TIV, CONT_TIV, TIME_TIV from eqe.dbo.'+@tmpExpTbl+' t1, eqe.dbo.COUNTRY t2, eqe.dbo.STATEL t3 where t1.COUNTRYKEY = t2.COUNTRYKEY and t3.COUNTRY_ID = t2.COUNTRY_ID and t1.LEV1_DATA = t3.STATE_2'

	exec absp_Util_UnloadData 'q', @sql, @filepath, '|'


	-- Now unload a file that has rollup by country

	exec absp_Util_GetWceDBDir @filepath output
	set @filepath = replace (@filepath, '/', '\\')
	set @filePath = ltrim(rtrim(@filepath)) + 'Exposure Report for ' + ltrim(rtrim(@rportName))
	exec absp_Util_createFolder @filepath
	set @filePath = ltrim(rtrim(@filepath)) +'\\By Country Exposure Report for ' + ltrim(rtrim(@rportName)) + '.txt';
	print @filePath
	set @sql = 'unload
						select distinct trim(COUNTRY) COUNTRY, sum(BLDG_TIV), sum(CONT_TIV), sum(TIME_TIV) from #TMP_EXP_TBL t1, COUNTRY t2
							where t1.COUNTRYKEY = t2.COUNTRYKEY
						group by COUNTRY

						order by COUNTRY

						to ''' + @filepath + ''' delimited by ''|'' format ascii quotes off'

	if (@debugFlag > 0)
		exec absp_MessageEx @sql

	set @sql = 'select distinct ltrim(rtrim(COUNTRY)) COUNTRY, sum(BLDG_TIV), sum(CONT_TIV), sum(TIME_TIV) from eqe.dbo.'+@tmpExpTbl+' t1, eqe.dbo.COUNTRY t2 where t1.COUNTRYKEY = t2.COUNTRYKEY group by COUNTRY order by COUNTRY'


	exec absp_Util_UnloadData 'q', @sql, @filepath, '|'

-------------- end --------------------

	exec('drop table '+@tmpExpTbl)
	set @msg = @me + 'complete'
	exec absp_messageEx @msg

end
