if exists(select * from SYSOBJECTS where ID = object_id(N'absp_0009380_MigrateCrestaVintage') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_0009380_MigrateCrestaVintage;
end
go

create procedure absp_0009380_MigrateCrestaVintage
as

begin
	set nocount on;

	--0009380: Migration steps needed for Section 8.4.7 of the document "US283 - DD - Implement New Boundaries for Eurowind 2014 - 24 Countries"

	declare @expoKey int;
	declare @msg varchar(max);

	begin try

		declare curCVint cursor for select ExposureKey from ExposureInfo;
		open curCVint;
		fetch curCVint into @expoKey;
		while @@FETCH_STATUS =0
		begin

			Update ExposureModel Set CountryCode = 'ROU' where CountryCode = 'ROM' and ExposureKey = @expoKey;
			Update ImportPostCodePartialMatch Set CountryCode = 'ROU', SQL = Replace (SQL, 'countrycode = ''ROM''', 'countrycode = ''ROU''') where CountryCode = 'ROM' and ExposureKey = @expoKey;
			Update Structure set CountryCode = 'ROU', Locator = replace (Locator, 'ROM-%', 'ROU-%')  from Structure where CountryCode = 'ROM' and ExposureKey = @expoKey;
			Update Structure Set RegionKey = 1847 where RegionKey = 1851 and ExposureKey = @expoKey;
			Update Structure Set IsValid = 0, GeocodeLevelID = -11 where RegionKey in (Select RRgn_Key as RegionKey from RRgnList where Country_ID = 'NOR' and Name not like ('2006 CRESTA Zone%'))
				and ExposureKey = @expoKey;
			Update Structure Set CrestaVintage = 1999 where RegionKey in (Select RRgn_Key as RegionKey from RRgnList where Country_ID = 'CZE' and Name not like ('CRESTA - CZE%'))
				and ExposureKey = @expoKey;
			Update Structure Set CrestaVintage = 1999 where RegionKey in (Select RRgn_Key as RegionKey from RRgnList where Country_ID = 'PRT' and Name not like ('CRESTA - PRT%'))
				and ExposureKey = @expoKey;
			Update Structure Set CrestaVintage = 1999 where RegionKey in (Select RRgn_Key as RegionKey from RRgnList where Country_ID = 'ESP' and Name not like ('CRESTA - ESP%'))
				and ExposureKey = @expoKey;
			Update Structure Set CrestaVintage = 2007 where RegionKey in (Select RRgn_Key as RegionKey from RRgnList where Country_ID = 'DNK' and Name not like ('CRESTA - DNK%'))
				and ExposureKey = @expoKey;
			Update Structure Set CrestaVintage = 2006 where RegionKey in (Select RRgn_Key as RegionKey from RRgnList where Country_ID = 'HUN' and Name not like ('CRESTA - HUN%'))
				and ExposureKey = @expoKey;
			Update Structure Set CrestaVintage = 1999 where RegionKey in (Select RRgn_Key as RegionKey from RRgnList where Country_ID = 'LUX' and Name not like ('CRESTA - LUX%'))
				and ExposureKey = @expoKey;
			Update Structure Set CrestaVintage = 2006 where RegionKey in (Select RRgn_Key as RegionKey from RRgnList where Country_ID = 'NOR' and Name not like ('CRESTA - NOR%'))
				and ExposureKey = @expoKey;
			Update Structure Set CrestaVintage = 2006 where RegionKey in (Select RRgn_Key as RegionKey from RRgnList where Country_ID = 'ROU' and Name not like ('CRESTA - ROU%'))
				and ExposureKey = @expoKey;
			Update Structure Set CrestaVintage = 2006 where RegionKey in (Select RRgn_Key as RegionKey from RRgnList where Country_ID = 'SWE' and Name not like ('CRESTA - SWE%'))
				and ExposureKey = @expoKey;

			fetch curCVint into @expoKey;
		end
		close curCVint;
		deallocate curCVint;

	end try

	begin catch
		set @msg=ERROR_MESSAGE();
		raiserror (@msg, 16, 1);
	end catch

end;
