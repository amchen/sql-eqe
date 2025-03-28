if exists(select 1 FROM SYSOBJECTS WHERE id = object_id(N'absp_GetExcludeRunningJobList') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
	drop procedure absp_GetExcludeRunningJobList;
end
go

create procedure absp_GetExcludeRunningJobList
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:   The procedure returns a list of waiting and running jobs.
	       The following jobs are to be returned:-
	 	 Jobs with staus 'W' or 'R' having no entry in TaskInfo
	 	 Jobs whose parents are not running/waiting
	 	 Jobs whose parent critical jobs have failed
Returns:	Nothing
====================================================================================================
</pre>
</font>
##BD_END
*/

begin
	set nocount on;

	declare @BatchJobKey int;
	declare @BatchJobKey2 int;
	declare @DBName varchar(120);
	declare @NodeType int;
	declare @NodeKey int;
	declare @cnt1 int;
	declare @cnt2 int;
	declare @sql1 nvarchar(max);
	declare @sql2 nvarchar(max);
	declare @inList1 varchar(max);
	declare @inList2 varchar(max);

	declare @WaitingJobsTbl table (BatchJobKey int, NodeType int, NodeKey int, DBName varchar(120));
	declare @RunningJobsTbl table (BatchJobKey int, NodeType int, NodeKey int, DBName varchar(120));
	declare @ExcludeJobsTbl table (BatchJobKey int);

	--Get Waiting jobs info
	insert @WaitingJobsTbl (BatchJobKey, NodeType, NodeKey, DBName)
		select j.BatchJobKey, b.NodeType,
		  case b.NodeType when  0 then FolderKey
		 				  when  1 then AportKey
		 				  when  2 then PportKey
		 				  when  3 then RportKey
		 				  when 23 then RportKey
		 				  when  4 then AccountKey
		 				  when  7 then ProgramKey
		 				  when 27 then ProgramKey
		 				  when  8 then PolicyKey
		 				  when  9 then SiteKey
		 				  when 10 then CaseKey
		 				  when 30 then CaseKey
		 				  else  0
		  end as NodeKey, b.DBName
		 from #RunningJobsTbl j
		 join commondb..BatchJob b on j.BatchJobKey = b.BatchJobKey
		where b.Status in ('W','WL') and b.DBRefKey > 0 and b.JobTypeID in (0);

	--Get Running jobs info
	insert @RunningJobsTbl (BatchJobKey, NodeType, NodeKey, DBName)
		select j.BatchJobKey, b.NodeType,
		  case b.NodeType when  0 then FolderKey
		 				  when  1 then AportKey
		 				  when  2 then PportKey
		 				  when  3 then RportKey
		 				  when 23 then RportKey
		 				  when  4 then AccountKey
		 				  when  7 then ProgramKey
		 				  when 27 then ProgramKey
		 				  when  8 then PolicyKey
		 				  when  9 then SiteKey
		 				  when 10 then CaseKey
		 				  when 30 then CaseKey
		 				  else  0
		  end as NodeKey, b.DBName
		 from #RunningJobsTbl j
		 join commondb..BatchJob b on j.BatchJobKey = b.BatchJobKey
		where b.Status in ('R','W','WL') and b.DBRefKey > 0 and b.JobTypeID in (0);

	-- Loop Waiting jobs
	declare cursWaitingJob cursor fast_forward for
		select BatchJobKey, NodeType, NodeKey, DBName
			from @WaitingJobsTbl
			order by BatchJobKey desc;

	open cursWaitingJob;
	fetch next from cursWaitingJob into @BatchJobKey, @NodeType, @NodeKey, @DBName;
   	while @@fetch_status = 0
   	begin
   		--Perform task only if database is attached--
		if exists (select 1 from  sys.databases where name= @DBName and state_desc = 'online' collate SQL_Latin1_General_CP1_CI_AS )
		begin
			set @inList1 = '';
			if (@nodeType = 4)
				set @sql1 = 'exec [@DBName].dbo.absp_Util_GenInList @inList1 out, ''select distinct ExposureKey from commondb..BatchJob where AccountKey=@nodeKey and BatchJobKey=@BatchJobKey'' , ''N''';
			else if (@nodeType = 9)
				set @sql1 = 'exec [@DBName].dbo.absp_Util_GenInList @inList1 out, ''select distinct ExposureKey from commondb..BatchJob where SiteKey=@nodeKey and BatchJobKey=@BatchJobKey'' , ''N''';
			else
				set @sql1 = 'exec [@DBName].dbo.absp_Util_GetExposureKeyList @inList1 out, @NodeKey, @NodeType';

			set @sql1 = replace(@sql1, '@DBName', @DBName);
			set @sql1 = replace(@sql1, '@NodeKey', cast(@NodeKey as varchar(30)));
			set @sql1 = replace(@sql1, '@NodeType', cast(@NodeType as varchar(30)));
			set @sql1 = replace(@sql1, '@BatchJobKey', cast(@BatchJobKey as varchar(30)));
			execute sp_executesql @sql1, N'@inList1 varchar(max) output', @inList1 output;

			set @cnt1 = -1;
			if len(dbo.trim(@inList1))>0
			begin
				set @sql1 = 'select @cnt1=count(*) from [@DBName].dbo.ExposureMap where ExposureKey @inList1';
				set @sql1 = replace(@sql1, '@DBName', @DBName);
				set @sql1 = replace(@sql1, '@inList1', @inList1);
				execute sp_executesql @sql1, N'@cnt1 int output', @cnt1 output;
			end

			-- Loop Running jobs for the same database
			declare cursRunningJob cursor fast_forward for
				select BatchJobKey, NodeType, NodeKey
					from @RunningJobsTbl where DBName = @DBName and BatchJobKey <> @BatchJobKey
					order by BatchJobKey;

			open cursRunningJob;
			fetch next from cursRunningJob into @BatchJobKey2, @NodeType, @NodeKey;
			while @@fetch_status = 0
			begin

				set @inList2 = '';
				if (@nodeType = 4)
					set @sql2 = 'exec [@DBName].dbo.absp_Util_GenInList @inList2 out, ''select distinct ExposureKey from commondb..BatchJob where AccountKey=@nodeKey and BatchJobKey=@BatchJobKey2'' , ''N''';
				else if (@nodeType = 9)
					set @sql2 = 'exec [@DBName].dbo.absp_Util_GenInList @inList2 out, ''select distinct ExposureKey from commondb..BatchJob where SiteKey=@nodeKey and BatchJobKey=@BatchJobKey2'' , ''N''';
				else
					set @sql2 = 'exec [@DBName].dbo.absp_Util_GetExposureKeyList @inList2 out, @NodeKey, @NodeType';

				set @sql2 = replace(@sql2, '@DBName', @DBName);
				set @sql2 = replace(@sql2, '@NodeKey', cast(@NodeKey as varchar(30)));
				set @sql2 = replace(@sql2, '@NodeType', cast(@NodeType as varchar(30)));
				set @sql2 = replace(@sql2, '@BatchJobKey2', cast(@BatchJobKey2 as varchar(30)));
				execute sp_executesql @sql2, N'@inList2 varchar(max) output', @inList2 output;

				set @cnt2 = -1;
				if len(dbo.trim(@inList1))>0 and len(dbo.trim(@inList2))>0
				begin
					set @sql2 = 'select @cnt2=count(*) from [@DBName].dbo.ExposureMap where ExposureKey @inList1 and ExposureKey not @inList2'
					set @sql2 = replace(@sql2, '@DBName', @DBName);
					set @sql2 = replace(@sql2, '@inList1', @inList1);
					set @sql2 = replace(@sql2, '@inList2', @inList2);
					execute sp_executesql @sql2, N'@cnt2 int output', @cnt2 output;

					if (@cnt1 <> @cnt2)
						insert @ExcludeJobsTbl (BatchJobKey) values (@BatchJobKey);
				end

				fetch next from cursRunningJob into @BatchJobKey2, @NodeType, @NodeKey;
			end
			close cursRunningJob;
			deallocate cursRunningJob;

			-- Remove Excluded jobs from Running jobs
			delete @RunningJobsTbl where BatchJobKey in (select BatchJobKey from @ExcludeJobsTbl);
		end
		fetch next from cursWaitingJob into @BatchJobKey, @NodeType, @NodeKey, @DBName;
	end
	close cursWaitingJob;
	deallocate cursWaitingJob;

	select distinct BatchJobKey from @ExcludeJobsTbl order by  BatchJobKey;
 end
