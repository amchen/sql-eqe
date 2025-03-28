if exists(select * from SYSOBJECTS where ID = object_id(N'absp_0008912_DropViews') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_0008912_DropViews;
end
go

create procedure absp_0008912_DropViews
as

begin
	set nocount on;

	--0008912: After migrating commondb database, there are some views for tables in systemdb that no longer exist

    declare @msg varchar(max);
    declare @sql varchar(1000);
	declare @viewName varchar(120);
	declare @viewTable table (viewName varchar(120));

	-- Views to be dropped
	insert @viewTable (viewName) values ('APLAYOUT');
	insert @viewTable (viewName) values ('CHASMODL');
	insert @viewTable (viewName) values ('DEWTFACT');
	insert @viewTable (viewName) values ('DEWTINFO');
	insert @viewTable (viewName) values ('DICTNOED');
	insert @viewTable (viewName) values ('DICTORD');
	insert @viewTable (viewName) values ('ExtPostC');
	insert @viewTable (viewName) values ('FILETYPE');
	insert @viewTable (viewName) values ('SAGPSVER');
	insert @viewTable (viewName) values ('STRINGS');
	insert @viewTable (viewName) values ('WstGrp0');
	insert @viewTable (viewName) values ('ZZ_ARCORDER');
	insert @viewTable (viewName) values ('ZZ_ARCPLCTL');
	insert @viewTable (viewName) values ('ZZ_ARCSEQ');
	insert @viewTable (viewName) values ('ZZ_AREACORD');
	insert @viewTable (viewName) values ('ZZ_FINDREGN');
	insert @viewTable (viewName) values ('ZZ_LFMP310');
	insert @viewTable (viewName) values ('ZZ_LFMP90');
	insert @viewTable (viewName) values ('ZZ_LFN31');
	insert @viewTable (viewName) values ('ZZ_LFN90');
	insert @viewTable (viewName) values ('ZZ_LFRP31');
	insert @viewTable (viewName) values ('ZZ_LFRP90');
	insert @viewTable (viewName) values ('ZZ_LFSSI31');
	insert @viewTable (viewName) values ('ZZ_LFSSI90');
	insert @viewTable (viewName) values ('ZZ_PERIL');
	insert @viewTable (viewName) values ('ZZ_RPTJOBS');
	insert @viewTable (viewName) values ('ZZ_SANITYTB');
	insert @viewTable (viewName) values ('ZZ_SITE_LD');
	insert @viewTable (viewName) values ('ZZ_UPDTRULE');
	insert @viewTable (viewName) values ('ZZ_ARCINFO');
	insert @viewTable (viewName) values ('ZZ_ARCPRGRS');
	insert @viewTable (viewName) values ('ZZ_ARCSVRCFG');
	insert @viewTable (viewName) values ('ZZ_RBATDBG');
	insert @viewTable (viewName) values ('ZZ_SESSIONS');
	insert @viewTable (viewName) values ('absvw_GetDistinctCurrencyCodesByPortId');
	insert @viewTable (viewName) values ('absvw_Mappings');
	insert @viewTable (viewName) values ('CHASAUTH');
	insert @viewTable (viewName) values ('CHASSTAT');
	insert @viewTable (viewName) values ('PFaults02_WCe316');
	insert @viewTable (viewName) values ('PfNodes02_WCe316');
	insert @viewTable (viewName) values ('PQuakes02_WCe316');
	insert @viewTable (viewName) values ('RBATINFO');
	insert @viewTable (viewName) values ('RBATJOB');
	insert @viewTable (viewName) values ('SEQPLNIN');

	begin try

		declare cursView cursor fast_forward for
			select viewName from @viewTable;
		open cursView;
		fetch next from cursView into @viewName;
		while @@fetch_status = 0
		begin
			-- drop 'view' from the database if exists
			if exists (select 1 from SYSOBJECTS where id = OBJECT_ID(@viewName) and OBJECTPROPERTY(id, N'IsView') = 1)
			begin
				 set @sql = 'drop view ' + @viewName;
                 exec absp_MessageEx @sql;
				 exec (@sql);
			end

			fetch next from cursView into @viewName;
		end

		close cursView;
		deallocate cursView;

	end try

	begin catch
		set @msg=ERROR_MESSAGE();
		raiserror (@msg, 16, 1);
	end catch

end;
