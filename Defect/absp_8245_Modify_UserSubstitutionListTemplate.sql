if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_8245_Modify_UserSubstitutionListTemplate') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_8245_Modify_UserSubstitutionListTemplate
end
go

create procedure absp_8245_Modify_UserSubstitutionListTemplate @tmplInfoKey integer = 0
as
begin

	set nocount on;


	-- XML data types require these settings
	-- http://msdn.microsoft.com/en-us/library/ms188285.aspx

	SET ANSI_PADDING ON;
	SET ANSI_NULL_DFLT_ON ON;
	SET ANSI_NULLS ON;

	declare @MappingField varchar(50);
	declare @lookupID int;
	declare @RQECode varchar(50);
	declare @country varchar(20);
	declare @userCode varchar(20);
	declare @templateInfoKey int;
	declare @sql varchar(max);
	declare @sql1 varchar(max);
	declare @cnt int;
	declare @i int;
	declare @debug int;
	declare @dt varchar(14);

	set @debug=0;

	--create table variables--
	create table #TempInfo (TemplateInfoKey int, TemplateXML xml );
	create table #TempMapping
		(TemplateInfoKey int,
		MappingField varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS,
		LookupID int,
		RQECode varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS,
		Country varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS,
		UserCode varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS);
	create table #TempTbl
		(Cnt int,
		MappingField varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS,
		LookupID int,
		RQECode varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS,
		Country varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS,
		UserCode varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS);

	--Get all substitutionList templates--
	set @sql1 ='insert into  #TempInfo  (TemplateInfoKey,TemplateXML)
		select TemplateInfoKey, cast(TemplateXML as xml)
		from commondb.dbo.TemplateInfo where templatetype=6 ';
	if	@tmplInfoKey > 0
		set @sql1 = @sql1 + ' and TemplateInfoKey = ' + CAST(@tmplInfoKey as varchar(10));
	set @sql1 = @sql1 + ' order by TemplateInfoKey';
	exec (@sql1);
	;WITH Mappings as
	(
    	SELECT
        	TemplateInfoKey,
       	 	MappingField = XMap.value('@MappingField', 'varchar(30)'),
       	 	LookupID= XMap.value('@LookupID','int'),
        	RQECode= XMap.value('@RQECode', 'varchar(50)'),
        	Country= XMap.value('@Country', 'varchar(20)'),
        	UserCode= XMap.value('@UserCode', 'varchar(20)')
    	FROM #TempInfo
    	CROSS APPLY TemplateXML.nodes('/UserSubstitutionList/SubstitutionData') as XTbl(XMap)
	) insert into #TempMapping select * from Mappings

	-- Due to defect 0008176, there might be some duplicate entries for Earthquake Occupancy Type, Flood Occupancy Type and Wind Occupancy Type
	--and those needs to be removed from the XML.
	declare curs1 cursor for select distinct TemplateInfoKey from #TempMapping
	open curs1
	fetch curs1 into @templateInfoKey
	while @@fetch_status=0
	begin
		--Get duplicates --
		truncate table #TempTbl;

		insert into #TempTbl(Cnt,MappingField,LookupID,RQECode,Country,UserCode)
		select count(*) as Cnt,MappingField,LookupID,RQECode,Country,UserCode  from #TempMapping  where TemplateInfoKey=@templateInfoKey
			group by MappingField,LookupID,RQECode,Country,UserCode
			having count(*) > 1;

		set @i=1;
		declare curs2 cursor for select MappingField,LookupID,RQECode,Country,UserCode from #TempMapping where TemplateInfoKey=@templateInfoKey
		open curs2
		fetch curs2 into @MappingField,@lookupId,@rqeCode,@country,@userCode
		while @@fetch_status=0
		begin
			if exists(select 1 from #TempTbl where MappingField=@MappingField and LookupID=@lookupId and RqeCode=@rqeCode and Country=@country and UserCode=@userCode)
			begin
				--Delete Node--
				set @sql = 'update #TempInfo
					set TemplateXML.modify(''delete /UserSubstitutionList[1]/SubstitutionData[' + cast(@i as varchar(10)) + ']'') where TemplateInfoKey= ' + cast(@templateInfoKey as varchar(10));
				if @debug=1 exec absp_MessageEx @sql;
				exec (@sql);

				--Delete from @TempMapping--
				set @sql = 'delete  top(1) from #TempMapping where  TemplateInfoKey = ' + cast(@templateInfoKey as varchar(10)) + ' and ' +
				' MappingField=''' + @MappingField + ''' and LookupID=' +cast(@lookupId as varchar(10)) + ' and RqeCode=''' + @rqeCode +
				 ''' and Country=''' + @country + ''' and UserCode=''' + @userCode + '''';
				if @debug=1 exec absp_MessageEx @sql;
				execute (@sql);

				delete from #TempTbl where MappingField=@MappingField and LookupID=@lookupId and RqeCode=@rqeCode and Country=@country and UserCode=@userCode;
			end

			set @i=@i+1
			fetch curs2 into @MappingField,@lookupId,@rqeCode,@country,@userCode
		end
		close curs2;
		deallocate curs2;
		fetch curs1 into  @templateInfoKey
	end
	close curs1;
	deallocate curs1;

	--For each TemplateInfo key updateXML
	declare curs1 cursor for select distinct TemplateInfoKey from  #TempMapping
	open curs1
	fetch curs1 into @templateInfoKey
	while @@fetch_status=0
	begin
		set @i=1;
		--Add attribute ShowInUI--
		declare curs2 cursor for select MappingField,LookupID,RQECode,Country,UserCode from  #TempMapping
			where TemplateInfoKey=@templateInfoKey

		open curs2
		fetch curs2 into @MappingField,@lookupId,@rqeCode,@country,@userCode;
		while @@fetch_status=0
		begin

			if @debug=1
			begin
				set @sql = 'MappingField=@MappingField, lookupId=@lookupId, rqeCode=@rqeCode, country=@country, userCode=@userCode';
				set @sql = replace(@sql,'@MappingField',@MappingField);
				set @sql = replace(@sql,'@lookupId',cast(@lookupId as varchar(20)));
				set @sql = replace(@sql,'@rqeCode',@rqeCode);
				set @sql = replace(@sql,'@country',@country);
				set @sql = replace(@sql,'@userCode',@userCode);
				exec absp_MessageEx @sql;
			end

			--Add attribute ShowInUI = 'True' to all except Earthquake,Flood and Wind  Occupancy/Structure Types--
			if  @MappingField not in ('Earthquake Occupancy Type','Flood Occupancy Type','Wind Occupancy Type',
			                          'Earthquake Structure Type','Flood Structure Type','Wind Structure Type')
			begin
				set @sql = 'update #TempInfo
					set TemplateXML.modify(''insert (attribute ShowInUI {"True"}) into (/UserSubstitutionList[1]/SubstitutionData['+ cast(@i as varchar(10)) +'])'')
					where TemplateXML.exist(''(/UserSubstitutionList[1]/SubstitutionData[' + cast(@i as varchar(10))+'])[empty(@ShowInUI)]'') = 1
					and TemplateInfoKey= ' + cast(@templateInfoKey as varchar(10));
				if @debug=1 exec absp_MessageEx @sql;
				exec (@sql);
			end

			-- For Occupancy and Structure types, following three entries are for Earthquake, Flood and Wind
			-- If these have the same LookupID, RQECode, Country, UserCode as the generic type add attribute ShowInUI = 'False'
			truncate table #TempTbl;

			if @MappingField = 'Occupancy Type'
			begin
				insert into #TempTbl(MappingField,LookupID,RQECode,Country,UserCode )
				select  MappingField,LookupID,RQECode,Country,UserCode  from  #TempMapping
					where TemplateInfoKey=@templateInfoKey and MappingField in ('Earthquake Occupancy Type','Flood Occupancy Type','Wind Occupancy Type')
					and LookupID=@lookupId and RQECode=@rqeCode and Country=@country and UserCode=@userCode;
			end
			else if @MappingField = 'Structure Type'
			begin
				insert into #TempTbl(MappingField,LookupID,RQECode,Country,UserCode )
				select  MappingField,LookupID,RQECode,Country,UserCode  from  #TempMapping
					where TemplateInfoKey=@templateInfoKey and MappingField in ('Earthquake Structure Type','Flood Structure Type','Wind Structure Type')
					and LookupID=@lookupId and RQECode=@rqeCode and Country=@country and UserCode=@userCode;
			end

			if @MappingField in ('Occupancy Type','Structure Type')
			begin
				if (select count(*) from #TempTbl where MappingField in ('Earthquake Occupancy Type','Flood Occupancy Type','Wind Occupancy Type',
                                                                         'Earthquake Structure Type','Flood Structure Type','Wind Structure Type'))=3
				begin
					set @sql = 'update #TempInfo
							set TemplateXML.modify(''insert (attribute ShowInUI {"False"}) into (/UserSubstitutionList[1]/SubstitutionData['+ cast(@i+1 as varchar(10)) +'])'')
							where TemplateXML.exist(''(/UserSubstitutionList[1]/SubstitutionData[' + cast(@i+1 as varchar(10))+'])[empty(@ShowInUI)]'') = 1
							and TemplateInfoKey = ' + cast(@templateInfoKey as varchar(10));
					if @debug=1 exec absp_MessageEx @sql;
		       		exec (@sql);

					set @sql = 'update #TempInfo
							set TemplateXML.modify(''insert (attribute ShowInUI {"False"}) into (/UserSubstitutionList[1]/SubstitutionData['+ cast(@i+2 as varchar(10)) +'])'')
							where TemplateXML.exist(''(/UserSubstitutionList[1]/SubstitutionData[' + cast(@i+2 as varchar(10))+'])[empty(@ShowInUI)]'') = 1
							and TemplateInfoKey = ' + cast(@templateInfoKey as varchar(10));
					if @debug=1 exec absp_MessageEx @sql;
		       		exec (@sql);

					set @sql = 'update #TempInfo
							set TemplateXML.modify(''insert (attribute ShowInUI {"False"}) into (/UserSubstitutionList[1]/SubstitutionData['+ cast(@i+3 as varchar(10)) +'])'')
							where TemplateXML.exist(''(/UserSubstitutionList[1]/SubstitutionData[' + cast(@i+3 as varchar(10))+'])[empty(@ShowInUI)]'') = 1
							and TemplateInfoKey = ' + cast(@templateInfoKey as varchar(10));
					if @debug=1 exec absp_MessageEx @sql;
		       		exec (@sql);
		       	end
			end
			else
			begin
				if @MappingField in ('Earthquake Occupancy Type','Flood Occupancy Type','Wind Occupancy Type',
									 'Earthquake Structure Type','Flood Structure Type','Wind Structure Type')
				begin
					set @sql = 'update #TempInfo
							set TemplateXML.modify(''insert (attribute ShowInUI {"True"}) into (/UserSubstitutionList[1]/SubstitutionData['+ cast(@i as varchar(10)) +'])'')
							where TemplateXML.exist(''(/UserSubstitutionList[1]/SubstitutionData[' + cast(@i as varchar(10))+'])[empty(@ShowInUI)]'') = 1
							and TemplateInfoKey = ' + cast(@templateInfoKey as varchar(10));
					if @debug=1 exec absp_MessageEx @sql;
					exec (@sql);
				end
			end

			set @i = @i + 1;
			fetch curs2 into @MappingField,@lookupId,@rqeCode,@country,@userCode;
		end
		close curs2
		deallocate curs2

		--Update Templateinfo.TemplateXML
		exec absp_Util_GetDateString @dt output;

		update commondb..TemplateInfo
			set TemplateXML=CONVERT(varchar(max), T2.TemplateXML),ModifyDate=@dt
			from commondb..TemplateInfo T1
				inner join #TempInfo T2 on T1.TemplateInfoKey=T2.TemplateInfoKey
				where T2.TemplateInfoKey=@templateInfoKey;

		fetch curs1 into @templateInfoKey;
	end
	close curs1
	deallocate curs1

end
