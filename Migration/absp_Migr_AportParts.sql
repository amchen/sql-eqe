if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_AportParts') and objectproperty(ID,N'isprocedure') = 1)
begin
	drop procedure absp_Migr_AportParts
end
go

create procedure absp_Migr_AportParts @oldAportKey int ,@newAportKey int,@linkedServerName varchar(200), @sourceDB varchar(200)
as
begin

	set nocount on
	declare @tabStep varchar(2)
	declare @oldRtroKey int
	declare @tTypeID int
	declare @whereClause varchar(8000)
	declare @progkeyTrio varchar(8000)
	declare @whereClause2 varchar(8000)
	declare @progkeyTrio2 varchar(8000)
	declare @whereClause3 varchar(8000)
	declare @progkeyTrio3 varchar(8000)
	declare @newRtroKey int
	declare @oldLayrKey int
	declare @newLayrKey int
	declare @newKey int
	declare @sql nvarchar(max)
	declare @sql2 nvarchar(max)
	declare @sSql nvarchar(max)
	declare @mapExists int
	
	execute  absp_GenericTableCloneSeparator @tabStep output
	
	set @sql='select  RTRO_KEY ,TTYPE_ID  from ' +@linkedServerName + '.[' + @sourceDB+'].dbo.RTROINFO where PARENT_KEY = ' + cast(@oldAportKey as varchar(20)) + ' and PARENT_TYP = 1 order by rtro_Key'
	
	execute('declare curs_rtro cursor global for '+@sql)	
	open curs_rtro
	fetch next from curs_rtro into @oldRtroKey,@tTypeID 
	while @@fetch_status = 0
	begin

		set @whereClause = 'PARENT_KEY = '+STR(@oldAportKey)+' AND RTRO_KEY = '+STR(@oldRtroKey)
		set @progkeyTrio = 'INT'+@tabStep+'PARENT_KEY '+@tabStep+str(@newAportKey)

		-- copy over each retro individually getting the new rtrokey
		execute @newRtroKey = absp_Migr_TableCloneRecords 'RTROINFO',1,@whereClause,@progkeyTrio,@linkedServerName,@sourceDB 
		print '@newRtroKey  '+ str(@newRtroKey)
		
		
		set @whereClause = 'RTRO_KEY = '+STR(@oldRtroKey)
		set @progkeyTrio = 'INT'+@tabStep+'RTRO_KEY '+@tabStep+STR(@newRtroKey)
		
		
		-- For Per Risk and Surplus Share the Reinsurer Information is at Treaty level and the
		-- Layer Key is always 0. So clone the records for each treaty

		if(@tTypeID = 6 or @tTypeID= 8)
			execute absp_Migr_TableCloneRecords  'RTROPART',0,@whereClause,@progkeyTrio,@linkedServerName,@sourceDB 

		set @sql2='select  RTLAYR_KEY from ' +@linkedServerName + '.[' + @sourceDB+'].dbo.RTROLAYR where RTRO_KEY = ' + cast(@oldRtroKey as varchar(20)) + ' order by rtLayr_Key'
		execute('declare curs2_trv cursor global for '+@sql2)	
		open curs2_trv
		fetch next from curs2_trv into @oldLayrKey
		while @@fetch_status = 0
		begin
			set @whereClause = 'RTLAYR_KEY = '+STR(@oldLayrKey)

			--RTROLAYR.SS_RETLINE in 3.16 migrates to RTROLAYR.Pr_Attach in RQE
			--RTROLAYR.SS_MAXLINE *SS_RETLINE migrates to RTROLAYR.Pr_Limit

			set @sSql =  ' insert into RtroLayr (Rtro_Key, Lnumber, Occ_Limit, Occ_Attach, Pct_Assume, Pct_Place,Agg_Limit, Agg_Attach, Premium, 
								Subj_Prem, ElossRatio, Rein_Count, Pr_Attach, Pr_Limit, Pr_Assume, Pr_Num_Pol,Eloss_Beta, 
								Atth_Ratio, Agg_Ratio,Pr_Ceded, Ss_Maxline, Ss_Retline, Cob_Id, Treaty_Id,  Rllim_Val, Rllim_Cc, 
								Rlatt_Val,Rlatt_Cc,Rlagg_Val,Rlagg_Cc, Rlprem_Val, Rlprem_Cc, Rlsprm_Val, Rlsprm_Cc, Rlpra_Val, 
			  					Rlpra_Cc,RlPrl_Val ,RlPrl_CC , Rlret_Val, Rlret_Cc, Rlaat_Val, Rlaat_Cc, FilterFrm,Filterto)
					select  ' + cast(@newRtroKey as varchar(20)) + ', a.Lnumber, a.Occ_Limit, a.Occ_Attach, a.Pct_Assume, a.Pct_Place,a.Agg_Limit,
								a.Agg_Attach, a.Premium,a.Subj_Prem, a.ElossRatio, a.Rein_Count, 
								case when b.ttype_id = 6 then a.Ss_Retline else a.Pr_Attach end, 
								case when b.ttype_id = 6 then a.Ss_Maxline * a.Ss_Retline else a.Pr_Limit end,
								a.Pr_Assume, a.Pr_Num_Pol,a.Eloss_Beta, a.Atth_Ratio, a.Agg_Ratio,a.Pr_Ceded, a.Ss_Maxline, 
								a.Ss_Retline, 0, a.Treaty_Id, a.Rllim_Val, a.Rllim_Cc, 
								a.Rlatt_Val,a.Rlatt_Cc,a.Rlagg_Val,a.Rlagg_Cc, a.Rlprem_Val, a.Rlprem_Cc, a.Rlsprm_Val, a.Rlsprm_Cc, a.Rlpra_Val, 
			  					a.Rlpra_Cc,a.RlPrl_Val ,a.RlPrl_CC , a.Rlret_Val, a.Rlret_Cc, a.Rlaat_Val, a.Rlaat_Cc, a.FilterFrm,a.Filterto 
			  		from  '+ @linkedServerName+'.[' + @sourceDB + '].dbo.RtroLayr a inner join ' + @linkedServerName+'.[' + @sourceDB + '].dbo.RtroInfo b
					on a.Rtro_Key=b.Rtro_Key and RTLAYR_KEY= '+cast(@oldLayrKey as char)
					
					exec absp_MessageEx @sSql		
					exec(@sSql)


			select  @newLayrKey = IDENT_CURRENT ('RtroLayr')
		
			-- now for each layer we have to clone the pieces
			set @whereClause2 = 'RTRO_KEY = '+STR(@oldRtroKey)+' AND '+'RTLAYR_KEY = '+STR(@oldLayrKey)
			set @progkeyTrio2 = 'INT'+@tabStep+' RTRO_KEY '+@tabStep+STR(@newRtroKey)+@tabStep+'INT'+@tabStep+' RTLAYR_KEY '+@tabStep+STR(@newLayrKey)


			--Migrate RtroExcl--
			--Fixed defect 5226----RtroExcl migration rules--
			set @sSql =  ' insert into RtroExcl (Rtro_Key,RtLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,Excl_Value )'+
					' select distinct ' + dbo.trim(cast(@newRtroKey as varchar(20))) + ',' + dbo.trim(cast(@newLayrKey as varchar(20))) + 
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
					from  '+ @linkedServerName+'.[' + @sourceDB + '].dbo.RtroExcl ';
			set @sSql = @sSql + ' mt   where mt.'+@whereClause;
			exec(@sSql)

			--Fixed defect 52266395: Tornado/Hail does not get migrated in layer exclusion
			---------------------------------
			select Rtro_Key,RtLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,Excl_Value
				into #TMP_RTROEXCL 
				from RtroExcl 
				where Excl_Type=1 and Excl_Value in (10,11) and RtLayr_Key = @newLayrKey 

			delete from RtroExcl where Excl_Type=1 and Excl_Value in(10,11) and RtLayr_Key = @newLayrKey 

			insert into RtroExcl (Rtro_Key,RtLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,Excl_Value )
				select Rtro_Key,RtLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type, 6  from #TMP_RTROEXCL 
					where Excl_Value=10
				union
				select Rtro_Key,RtLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,7  from #TMP_RTROEXCL 
					where Excl_Value=10

			insert into RtroExcl (Rtro_Key,RtLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,Excl_Value )
				select Rtro_Key,RtLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,1  from #TMP_RTROEXCL 
					where Excl_Value=11
				union
				select Rtro_Key,RtLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,6  from #TMP_RTROEXCL 
					where Excl_Value=11
				union
				select Rtro_Key,RtLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,7  from #TMP_RTROEXCL 
					where Excl_Value=11
				union
				select Rtro_Key,RtLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,8  from #TMP_RTROEXCL 
					where Excl_Value=11
				union
				select Rtro_Key,RtLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,9  from #TMP_RTROEXCL 
					where Excl_Value=11
				union
				select Rtro_Key,RtLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,15  from #TMP_RTROEXCL 
					where Excl_Value=11
				union
				select Rtro_Key,RtLayr_Key,Excl_Num,Excl_Mode,CGrp_Key,CList_Key,Grp_Excl,RRgnGrp_id,Excl_Type,95  from #TMP_RTROEXCL 
					where Excl_Value=11
					
			drop table #TMP_RTROEXCL 
			-----------------------------		
		

			-- For Per Risk and Surplus Share the Reinsurer Information is at Treaty level and the
			-- Layer Key is always 0. So we do not need to clone the records for each layer.
			if(@tTypeID <> 6 and @tTypeID <> 8)
				execute absp_Migr_TableCloneRecords  'RTROPART',0,@whereClause2,@progkeyTrio2,@linkedServerName,@sourceDB           

			--Clone Source.DBName.COBMAP to AportRtroLayerMap
			set @mapExists=-1
			set @sSql= 'select @mapExists= 1 from ' + @linkedServerName+'.['+@sourceDB +'].dbo.COBMAP where Aport_Key='+cast(@oldAportKey as varchar(20))+
				' and Rtro_Key = ' + cast(@oldRtroKey as varchar(20))+ ' and RtLayr_Key = ' + cast(@oldLayrKey as varchar(20))
			execute sp_executesql @sSql, N'@mapExists int OUTPUT', @mapExists OUTPUT
			if @mapExists = 1
			begin
				delete from AportRtroLayerMap where AportKey= @newAportKey and RtroKey=@newRtroKey and RtLayerKey=@newLayrKey
				insert into AportRtroLayerMap (AportKey,RtroKey,RtLayerKey) select @newAportKey,@newRtroKey,@newLayrKey
			end	
			
			-- Clone Source.DBName.RtroCob to RtroLineOfBusiness
			--ResolveLookupIds in absp_Migr_UpdateTreaty
			set @mapExists=-1
			set @sSql= 'select @mapExists= 1 from ' + @linkedServerName+'.['+@sourceDB +'].dbo.RtroCob where RtLayr_Key='+cast(@oldLayrKey as varchar(20))
			execute sp_executesql @sSql, N'@mapExists int OUTPUT', @mapExists OUTPUT
			if @mapExists = 1
			begin
				delete from RtroLineOfBusiness where RtLayerKey=@newLayrKey
				set @sSql = 'insert into RtroLineOfBusiness (RtLayerKey,LineOfBusinessId) 
					select ' + cast(@newLayrKey as varchar(20)) + ',COB_ID from ' + @linkedServerName+'.['+@sourceDB +'].dbo.RtroCob where RtLayr_Key='+cast(@oldLayrKey as varchar(20))
				exec(@sSql)
			end	
			
			
			fetch next from curs2_trv into  @oldLayrKey
		end
		close curs2_trv
		deallocate curs2_trv

		-- the zero = all_layers options
		set @whereClause3 = 'RTLAYR_KEY = 0 AND MT.RTRO_KEY = '+STR(@oldRtroKey)
		set @progkeyTrio3 = 'INT'+@tabStep+' RTRO_KEY '+@tabStep+STR(@newRtroKey)+@tabStep+'INT'+@tabStep+' RTLAYR_KEY '+@tabStep+STR(0)
		execute absp_Migr_TableCloneRecords  'RTROEXCL',1,@whereClause3,@progkeyTrio3,@linkedServerName,@sourceDB 

		-- For Per Risk and Surplus Share the Reinsurer Information is at Treaty level and the
		-- Layer Key is always 0. So we do not need to clone the records for each layer.
		if(@tTypeID <> 6 and @tTypeID <> 8)
			execute absp_Migr_TableCloneRecords  'RTROPART',0,@whereClause3,@progkeyTrio3,@linkedServerName,@sourceDB 

		fetch next from curs_rtro into @oldRtroKey,@tTypeID 
	end
	close curs_rtro
	deallocate curs_rtro


end
