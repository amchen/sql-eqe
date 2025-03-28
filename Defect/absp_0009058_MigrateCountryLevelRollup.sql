if exists(select * from SYSOBJECTS where ID = object_id(N'absp_0009058_MigrateCountryLevelRollup') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_0009058_MigrateCountryLevelRollup;
end
go

create procedure absp_0009058_MigrateCountryLevelRollup
as

begin
	set nocount on;

	--0009058: DB Migration: Make all Table Modifications Per US283 Design Spec

	declare @expoKey int;
	declare @msg varchar(max);

	begin try

		declare curCLR cursor for select ExposureKey from ExposureInfo;
		open curCLR;
		fetch curCLR into @expoKey;
		while @@FETCH_STATUS=0
		begin
			Update Structure Set IsValid = 0, GeocodeLevelID = -11
				where ExposureKey = @expoKey
				and RegionKey in (Select RRgn_Key as RegionKey from RRgnList where Name = 'Country Level Rollup');

			fetch curCLR into @expoKey;
		end
		close curCLR;
		deallocate curCLR;

	end try

	begin catch
		set @msg=ERROR_MESSAGE();
		raiserror (@msg, 16, 1);
	end catch

end;
