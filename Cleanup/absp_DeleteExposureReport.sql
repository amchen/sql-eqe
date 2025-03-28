if exists(select * from SYSOBJECTS where ID = object_id(N'absp_DeleteExposureReport') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_DeleteExposureReport;
end
go

create procedure absp_DeleteExposureReport
	@nodeKey int,
	@nodeType int,
	@IsBaseReport int=0
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:       The procedure cleans up the ExposureReport for the given nodeKey and nodeType.
Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/

begin

    set nocount on;

	declare @nKey int;
	declare @nType int;

	if (@IsBaseReport = 0)
	begin
		-- get all child nodes
		create table #NODELIST (NODE_KEY INT, NODE_TYPE INT, PARENT_KEY INT, PARENT_TYPE INT);
		execute absp_PopulateChildList @nodeKey, @nodeType;

		if (@nodeType = 2 or @nodeType = 7 or @nodeType = 27)
			insert #NODELIST (NODE_KEY,NODE_TYPE) values (@nodeKey,@nodeType);
		delete from #NODELIST where NODE_TYPE not in (2,7,27);

		declare curDeleteExposureReport cursor fast_forward for
			select NODE_KEY, NODE_TYPE from #NODELIST
		open curDeleteExposureReport
		fetch next from curDeleteExposureReport into @nKey, @nType;
		while @@fetch_status = 0
		begin
			begin tran;
				delete e from ExposureReport e inner join ExposureMap m
					on e.ExposureKey = m.ExposureKey
					and m.ParentKey = @nKey
					and m.ParentType = @nType;
				delete e from ExposureReportInfo e inner join ExposureMap m
					on e.ExposureKey = m.ExposureKey
					and m.ParentKey = @nKey
					and m.ParentType = @nType;
			commit tran;
			fetch next from curDeleteExposureReport into @nKey, @nType;
		end

		close curDeleteExposureReport;
		deallocate curDeleteExposureReport;

		drop table #NODELIST;
	end
end
