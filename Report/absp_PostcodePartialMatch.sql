if exists (select * from sys.objects where object_id = object_id(N'dbo.absp_PostcodePartialMatch') and type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
begin
	drop function dbo.absp_PostcodePartialMatch;
end
go



create function [dbo].[absp_PostcodePartialMatch]
(
	@ExposureKey int
)
returns @Report table
(
	ImportPostCodePartialMatchRowNum      integer,	
	ExposureKey			integer,
	SourceCategory		integer,
	CountryCode			varchar(3),
	OriginalPostcode	varchar(50),
	Postcode			varchar(20),
	PostcodeCount		integer,
	GeocodeLevelName	varchar(50),
	TIV					float,
	SQLQuery			varchar(20),
	SQL					varchar(500)


)
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:    This function returns the Import Postcode Partial Match report.
Example:    select * from dbo.absp_PostcodePartialMatch(<exposureKey>)
====================================================================================================
</pre>
</font>
##BD_END

##PD  @ExposureKey  ^^  Exposure key.
*/


/*
	If there are no ImportPostcodePartialMatch rows for the given ExposureKey then insert a "No Partial Postcodes" record for it.
	Then return all of the records with that ExposureKey
--*/
begin
	begin
		if not exists (select 1 from dbo.ImportPostcodePartialMatch where ExposureKey=@ExposureKey )
			insert @Report values (0,@ExposureKey,'','','No Postcodes Were Partially Matched','','','','','','');
	end



	insert @Report select distinct * from dbo.ImportPostcodePartialMatch where ExposureKey=@ExposureKey


	return;

end

/* This is the original version that produced the Import Postcode Partial Match report.
	and has been replaced by the code above that just selects the rows from
	table ImportPostcodePartialMatch that was generated during Geocoding
*/

/*
begin
	if exists (select 1 from Structure where ExposureKey=@ExposureKey)
	begin

	-- get the USD currency exchange rate
	declare @Currsk_key int;
	declare @USDExchgRate float;

	-- Currency Conversion Calculation:
	-- Given a StructureCoverage Value of 10 Eur, what is the value in USD?
	-- USD exchange = 1,  EUR exchange = .8
	--  10 * (1 / .8)  = 10 *  1.25 = 12.50

	select @Currsk_key = currsk_key from FldrInfo where Curr_Node = 'Y'
	select @USDExchgRate = ExchgRate from ExchRate where Currsk_Key = @Currsk_key and Code = 'USD';



		-- Use Common Table Expression (CTE)

		with PostCode_CTE
		(
			SourceCategory	,
			CountryCode		,
			GeocodeLevelDescription	,
			OriginalPostcode,
			Postcode		,
			PostcodeCount	,
			SQL

		)
		as
		(
			select InputSourceId, CountryCode, GeocodeLevelDescription, Postcode + PostcodeAux, PostCode, COUNT(Postcode),
			'SQL'=
			'select AccountNumber, Structurenumber, Structurename, postcode + postcodeaux ''Original Postcode'', ' +
			'Postcode ''Partially Matched Postcode''' +
			'from Structure ' +
			'join account on (account.exposurekey = structure.exposurekey and account.accountkey = structure.accountkey) ' +
			'where  postcode + postcodeaux = ''' + postcode + postcodeaux + ''' and len(postcodeaux)>0  and ' +
			'countrycode = ''' + CountryCode + ''' and structure.exposurekey = ' + cast(@ExposureKey as CHAR)

			from Structure t1

			inner join GeocodeLevel t3 on t1.GeocodeLevelID = t3.GeocodeLevel


			where ExposureKey = @ExposureKey
			and LEN(PostcodeAux) > 0

			group by InputSourceId, CountryCode, GeocodeLevelDescription, PostCode, PostcodeAux

		),

		 PostcodeValues_CTE( Postcode, value, sumValue)
		as
		(
			select Postcode, value, SUM(value * (@USDExchgRate / t3.ExchgRate))
			from Structure t1
			inner join StructureCoverage t2 on t1.ExposureKey = t2.ExposureKey and t1.StructureKey = t2.StructureKey
			inner join ExchRate t3 on t1.SiteCurrencyCode = t3.Code and t3.Active = 'Y' and
			t3.Currsk_Key = (select currsk_key from FldrInfo where Curr_Node = 'Y')
			where t1.ExposureKey = @ExposureKey and len(PostcodeAux) > 0

			group by Postcode, value

		)


		insert @Report
		(
			ExposureKey,
			SourceCategory	,
			CountryCode		,
			OriginalPostcode,
			Postcode		,
			PostcodeCount	,
			GeocodeLevelName,
			TIV,
			SQLQuery,
			SQL
		)

		select
			@ExposureKey,
			SourceCategory	,
			CountryCode		,
			OriginalPostcode,
			c1.Postcode		,
			PostcodeCount	,
			GeocodeLevelDescription	,
			sumValue		,
			'Show Sql Query',
			SQL


		 from PostCode_CTE c1, PostcodeValues_CTE c2 where c1.Postcode = c2.Postcode

	end

	begin
		if 0 = (select COUNT(*) from @Report)
			insert @Report values (@ExposureKey,'','','No Partial Postcodes','','','','','','');
	end

	return;
end
--*/
