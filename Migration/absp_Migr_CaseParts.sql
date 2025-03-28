if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_CaseParts') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_CaseParts
end
go

create procedure absp_Migr_CaseParts @oldCaseKey int, @newCaseKey int,@linkedServerName varchar(200), @sourceDB varchar(200)
as
begin

   	set nocount on
   	declare @newLayrKey int
   	declare @whereClause  varchar(8000)
   	declare @whereClause2  varchar(8000)
   	declare @progkeyTrio2  varchar(2000)
   	declare @whereClause3 varchar(8000)
   	declare @progkeyTrio3 varchar(2000)
	declare @tabStep varchar(2)
	declare @oldCaseLayrKey int
	declare @sql nvarchar(max)
	declare @sSql nvarchar(max)
	declare @caseCobExists int

	execute absp_GenericTableCloneSeparator  @tabStep output

	-- For each layr associated with that case_key
	set @sql='select  CSLAYR_KEY from ' +@linkedServerName + '.[' + @sourceDB+'].dbo.CASELAYR where CASE_KEY = ' + cast(@oldCaseKey as varchar(20)) + ' and CSLAYR_KEY > 0 order by CSLAYR_KEY'
	execute('declare curs2_Cslayr cursor global for '+@sql)

	open curs2_Cslayr
	fetch next from curs2_Cslayr into @oldCaseLayrKey
	while @@fetch_status = 0
	begin
		set @whereClause = 'CSLAYR_KEY = '+cast(@oldCaseLayrKey as char)
		
		--Surplus Share Treaty Migration Rules
		--CASELAYR.SS_RETLINE in 3.16 migrates to CASELAYR.Pr_Attach in RQE
		--CASELAYR.SS_MAXLINE *SS_RETLINE migrates to CASELAYR.Pr_Limit

		set @sSql =  ' insert into CaseLayr (Case_Key, Lnumber, Occ_Limit, Occ_Attach, Pct_Assume, Pct_Place, Uw_Prem, Calcr_Id,
 							Agg_Limit, Agg_Attach, Subj_Prem, Elossratio, Eloss_Beta, Atth_Ratio, Agg_Ratio, 
 							Pr_Ceded, Ss_Maxline, Ss_Retline, Cob_Id, Treaty_Id, Pr_Attach, Pr_Limit, Pr_Assume,
  							Pr_Num_Pol, Cllim_Val, Cllim_Cc, Clatt_Val, Clatt_Cc, Clprem_Val, Clprem_Cc, Clagg_Val, 
  							Clagg_Cc, Clret_Val, Clret_Cc, Claat_Val, Claat_Cc, Clsprm_Val, Clsprm_Cc, Clpra_Val, 
  							Clpra_Cc, Clprl_Val, Clprl_Cc )
					select  ' + cast(@newCaseKey as varchar(20)) + ', a.Lnumber, a.Occ_Limit, a.Occ_Attach, a.Pct_Assume, a.Pct_Place, a.Uw_Prem, a.Calcr_Id,
 							a.Agg_Limit, a.Agg_Attach, a.Subj_Prem, a.Elossratio, a.Eloss_Beta, a.Atth_Ratio, a.Agg_Ratio, 
 							a.Pr_Ceded, a.Ss_Maxline, a.Ss_Retline, 0, a.Treaty_Id, 
							case when b.ttype_id = 6 then a.Ss_Retline else a.Pr_Attach end, 
							case when b.ttype_id = 6 then a.Ss_Maxline * a.Ss_Retline else a.Pr_Limit end,
  							a.Pr_Assume,a.Pr_Num_Pol, a.Cllim_Val, a.Cllim_Cc, a.Clatt_Val, a.Clatt_Cc, a.Clprem_Val, a.Clprem_Cc, a.Clagg_Val, 
  							a.Clagg_Cc, a.Clret_Val, a.Clret_Cc, a.Claat_Val, a.Claat_Cc, a.Clsprm_Val, a.Clsprm_Cc, a.Clpra_Val, 
  							a.Clpra_Cc, a.Clprl_Val, a.Clprl_Cc
  					from  '+ @linkedServerName+'.[' + @sourceDB + '].dbo.CaseLayr a inner join ' + @linkedServerName+'.[' + @sourceDB + '].dbo.CaseInfo b
					on a.Case_Key=b.Case_Key and csLayr_Key= '+cast(@oldCaseLayrKey as char) 
 
		exec absp_MessageEx @sSql		
		exec(@sSql)
		
		select  @newLayrKey = IDENT_CURRENT ('CaseLayr')

		-- now for each layer we have to clone the pieces
		set @whereClause2 = 'CSLAYR_KEY = '+cast(@oldCaseLayrKey as char)
		set @progkeyTrio2 = 'int'+@tabStep+' CASE_KEY '+@tabStep+cast(@newCaseKey as char)+@tabStep+'int'+@tabStep+' CSLAYR_KEY '+@tabStep+cast(@newLayrKey as char)


		--Migrate CaseExcl--
		--Fixed defect 5226----CaseExcl migration rules--
		set @sSql =  ' insert into CaseExcl (Case_Key,CsLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,Excl_Value )'+
					' select distinct ' + dbo.trim(cast(@newCaseKey as varchar(20))) + ',' + dbo.trim(cast(@newLayrKey as varchar(20))) + 
					',Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,
					case when Excl_Type <>2 then Excl_Value 
					else
						case when Excl_Value<=8 or Excl_Value=1003 then 2
							when Excl_Value between 9 and 14 or Excl_Value=1001 then 9
							when Excl_Value in (15,19) or Excl_Value=1002 then 15
						else
							Excl_Value
						end
					end
					from  '+ @linkedServerName+'.[' + @sourceDB + '].dbo.CaseExcl ';
		set @sSql = @sSql + ' mt   where mt.'+@whereClause;
		exec absp_MessageEx @sSql
		exec(@sSql)
		
		--Fixed defect 52266395: Tornado/Hail does not get migrated in layer exclusion
		select Case_Key,CsLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,Excl_Value 
			into #TMP_CASEEXCL 
			from CaseExcl 
			where Excl_Type=1 and Excl_Value in (10,11) and CsLayr_Key = @newLayrKey 
			
		delete from CaseExcl where Excl_Type=1 and Excl_Value in(10,11) and CsLayr_Key = @newLayrKey 
		
		insert into CaseExcl (Case_Key,CsLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,Excl_Value )
			select Case_Key,CsLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,6  from #TMP_CASEEXCL 
				where Excl_Value=10
			union
			select Case_Key,CsLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,7  from #TMP_CASEEXCL 
				where Excl_Value=10
				
		insert into CaseExcl (Case_Key,CsLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,Excl_Value )
			select Case_Key,CsLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,1  from #TMP_CASEEXCL 
				where Excl_Value=11
			union
			select Case_Key,CsLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,6 from #TMP_CASEEXCL 
				where Excl_Value=11
			union
			select Case_Key,CsLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,7  from #TMP_CASEEXCL 
				where Excl_Value=11
			union
			select Case_Key,CsLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,8  from #TMP_CASEEXCL 
				where Excl_Value=11
			union
			select Case_Key,CsLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,9  from #TMP_CASEEXCL 
				where Excl_Value=11
			union
			select Case_Key,CsLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,15  from #TMP_CASEEXCL 
				where Excl_Value=11
			union
			select Case_Key,CsLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,95  from #TMP_CASEEXCL 
				where Excl_Value=11
		
		drop table #TMP_CASEEXCL 
		
		-------
		
		execute absp_Migr_TableCloneRecords 'CASEREIN',1,@whereClause2,@progkeyTrio2,@linkedServerName,@sourceDB

		-- Clone Source.DBName.CaseCob to CaseLineOfBusiness
		--ResolveLookupIds in absp_Migr_UpdateTreaty
		set @caseCobExists=-1
		set @sSql= 'select @caseCobExists= 1 from ' + @linkedServerName+'.['+@sourceDB +'].dbo.CaseCob where CsLayr_Key='+cast(@oldCaseLayrKey as varchar(20))
		execute sp_executesql @sSql, N'@caseCobExists int OUTPUT', @caseCobExists OUTPUT
		if @caseCobExists = 1
		begin
			delete from CaseLineOfBusiness where CsLayerKey=@newLayrKey
			set @sSql = 'insert into CaseLineOfBusiness (CsLayerKey,LineOfBusinessId) 
				select ' + cast(@newLayrKey as varchar(20)) + ',COB_ID from ' + @linkedServerName+'.['+@sourceDB +'].dbo.CaseCob where CsLayr_Key='+cast(@oldCaseLayrKey as varchar(20))
			exec(@sSql)
		end	
		
		fetch next from curs2_Cslayr into @oldCaseLayrKey
	end
	close curs2_Cslayr
	deallocate curs2_Cslayr

	-- the zero =all_layers options
	set @whereClause3 = 'CSLAYR_KEY = 0 and MT.CASE_KEY = '+cast(@oldCaseKey as char)
	set @progkeyTrio3 = 'int'+@tabStep+' CASE_KEY '+@tabStep+cast(@newCaseKey as char)+@tabStep+'int'+@tabStep+' CSLAYR_KEY '+@tabStep+cast(0 as char)
	begin try
		execute absp_Migr_TableCloneRecords 'CASEEXCL',1,@whereClause3,@progkeyTrio3,@linkedServerName,@sourceDB;
	end try
	begin catch
		-- catch errors due to non-existent CASEEXCL records
	end catch
	begin try
		execute absp_Migr_TableCloneRecords 'CASEREIN',1,@whereClause3,@progkeyTrio3,@linkedServerName,@sourceDB;
	end try
	begin catch
		-- catch errors due to non-existent CASEREIN records
	end catch
end
