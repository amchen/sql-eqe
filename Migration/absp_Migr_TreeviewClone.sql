if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_TreeviewClone') and objectproperty(id,N'IsProcedure') = 1)
	drop procedure absp_Migr_TreeviewClone;
go

create procedure absp_Migr_TreeviewClone
	@batchJobKey int,
	@lknServerName varchar(500),
	@sourceDB varchar(120),
	@sNodeKey  int = -1,
	@sNodeType int = -1,
	@newFldrKey int
as
begin
	set nocount on

	declare @longName nvarchar(400);
	declare @sql nvarchar(max);
	declare @currentNodeKey int;
	declare @createBy int;
	declare @groupKey int;
	declare @parentKey int;
	declare @parentType int;
	declare @sSql varchar(max);
	declare @newKey int;
	declare @newProgKey int;
	declare @retKey int;
	declare @nodeKey int;
	declare @nodeType int;
	declare @infoTableName varchar(120);
	declare @colName varchar(120);
	declare @tabStep varchar(2);
	declare @fieldValueTrios varchar(5000);
	declare @whereClause varchar(max);
	declare @newParentKey int;
	declare @usrKey int;
	declare @GrpKey int;
	declare @createDt varchar(14);
	declare @nodeName varchar(130);
	declare @targetDB varchar(120);
	declare @status int;
	declare @whereClauseForCase varchar(2000)

	exec absp_GenericTableCloneSeparator @tabStep output;

	create table #TMP_RTROKEYS (OldRtrokey int,NewRtroKey int )

	select @targetDB=KeyValue from BatchProperties where BatchJobKey=@batchJobKey and KeyName='Target.DatabaseName';

	--Get the user and group key--
	select @usrKey = UserKey from BatchJob where BatchJobKey=@batchJobKey;
	select @GrpKey = Group_Key from UsrGpMem where User_Key=@usrKey;
	exec absp_Util_GetDateString @createDt output, 'yyyymmddhhnnss';

	create table #TMPTREE (NodeKey int, NodeType int,ParentKey int,ParentType int);
	exec absp_Migr_CreateTreeHierarchy @sNodeKey, @sNodeType, @lknServerName, @sourceDB;

	declare @MyStr varchar(4000);
	declare @curTable varchar(120);

	create table #Tmp_Tbl(NodeKey int, NodeType int,ParentKey int,ParentType int, NewNodeKey int);
	--Make an entry for Currency Folder

	--Clone Lookups--
	truncate table treatytag;
	truncate table LineOFBusiness;
	truncate table Reinsurer;
	set @sql='set identity_insert TreatyTag on;'
	set @sql= @sql + 'insert into treatytag (TreatyTagID,Name,In_List,Dflt_Row)values(0,''UnSpecified'',''Y'',''Y'');'
	set @sql= @sql + 'insert into TreatyTag(TreatyTagID,Name,In_List,Dflt_Row)
			select TREATY_ID, U_TR_ID,IN_LIST, DFLT_ROW from '+ @lknServerName + '.[' +@sourceDB+'].dbo.TRTYL;'
	set @sql=@sql + 'set identity_insert TreatyTag off;'
	exec (@sql)

	set @sql='set identity_insert LineOFBusiness on;'
	set @sql= @sql + 'insert into LineOFBusiness (LineOfBusinessID,Name,In_List,Dflt_Row)values(0,''UnSpecified'',''Y'',''Y'');'
	set @sql= @sql + 'insert into LineOFBusiness(LineOfBusinessID,Name,In_List,Dflt_Row)
				select  COB_ID,U_COB_ID,IN_LIST, DFLT_ROW from '+ @lknServerName + '.[' +@sourceDB+'].dbo.COBL;'
	set @sql=@sql + 'set identity_insert LineOFBusiness off;'
	exec (@sql)

	set @sql='set identity_insert Reinsurer on;'
	set @sql= @sql + 'insert into Reinsurer (ReinsurerID,Name,In_List,Dflt_Row)values(0,''UnSpecified'',''Y'',''Y'');'
	set @sql= @sql + 'insert into Reinsurer(ReinsurerID,Name,In_List,Dflt_Row)
				select REINSR_ID,REINSR_NAM,IN_LIST, DFLT_ROW from '+ @lknServerName + '.[' +@sourceDB+'].dbo.RIL;'
	set @sql=@sql + 'set identity_insert Reinsurer off;'
	exec (@sql)

	declare MyCursor cursor fast_forward for select NodeKey,NodeType,ParentKey,ParentType from #TMPTREE where NodeType <> 12;
	open MyCursor
	fetch next from MyCursor into  @nodeKey, @nodeType, @parentkey, @parentType
	while @@fetch_status = 0
	begin
		set @whereClauseForCase  = ''

		if (@nodeType=0)
		begin
			set @infoTableName='FldrInfo';
			set @colName='Folder_key';
		end
		else if (@nodeType=1)
		begin--aport
			set @infoTableName='AprtInfo';
			set @colName='Aport_key';
		end
		else if (@nodeType=2)
		begin--pport
			set @infoTableName='PprtInfo';
			set @colName='Pport_key';
		end
		else if (@nodeType=23)
		begin--rport
			set @infoTableName='RprtInfo';
			set @colName='Rport_key';
		end
		else if (@nodeType=27)
		begin--prog
			set @infoTableName='ProgInfo';
			set @colName='Prog_key';
		end

		if (@nodeType=30)
		begin--treaty
			set @infoTableName='CaseInfo';
			set @whereClauseForCase = ' and Prog_Key='+cast(@parentKey as varchar(20));
			set @sql='select @longName=longName from '+ @lknServerName + '.[' +@sourceDB+'].dbo.CaseInfo where Case_Key ='+cast(@nodeKey as varchar(20)) +  @whereClauseForCase;
			set @whereClause='Case_Key=' + dbo.trim(cast(@nodeKey as varchar(10))) + @whereClauseForCase;
			exec absp_MessageEx @sql;
			execute sp_executesql @sql,N'@longName varchar(400) output',@longName output;

			-- Reset the Prog_Key to the newKey from the targetDB
			select top 1 @newProgKey=NewNodeKey from #Tmp_Tbl where NodeKey=@parentKey  and NodeType=27 and ParentType=23;
			set @whereClauseForCase = ' and Prog_Key='+cast(@newProgKey as varchar(20));
			set @fieldValueTrios = 'int'+@tabStep+'Prog_Key'+@tabStep+cast(@newProgKey as varchar(20))+@tabStep+'str'+@tabStep+'LONGNAME'+@tabStep+'RQE_'+@longName+@tabStep+'int'+@tabStep+'Create_By'+@tabStep+cast(@usrKey as varchar(20));
		end
		else
		begin
			set @sql='select @longName=longName from '+ @lknServerName + '.[' +@sourceDB+'].dbo.' + @infoTableName + ' where ' + @colName + '='+cast(@nodeKey as varchar(20));
			set @whereClause=@colName + '=' + dbo.trim(cast(@nodeKey as varchar(10)))
			exec absp_MessageEx @sql
			execute sp_executesql @sql,N'@longName varchar(400) output',@longName output;
			set @fieldValueTrios = 'str'+@tabStep+'LONGNAME'+@tabStep+'RQE_' + @longName + @tabStep + 'int'+@tabStep+'Create_By'+@tabStep+cast(@usrKey as varchar(20))+ @tabStep + 'int'+@tabStep+'Group_Key'+@tabStep+cast(@grpKey as varchar(20));
		end

		-- Check if the Info record has already been created
		set @nodeName = 'RQE_'+@longName;
		set @status = -1;
		set @sql = 'select @status=1,@newKey=@colName from [@targetDB].dbo.@infoTableName where LONGNAME=''@nodeName''' + @whereClauseForCase;
		set @sql = replace(@sql, '@colName', @colName);
		set @sql = replace(@sql, '@targetDB', @targetDB);
		set @sql = replace(@sql, '@infoTableName', @infoTableName);
		set @sql = replace(@sql, '@nodeName', @nodeName);
		exec absp_MessageEx @sql;
		execute sp_executesql @sql,N'@status int output,@newKey int output',@status output,@newKey output;

		if (@status <> 1)
		begin
			execute @newKey=absp_Migr_TableCloneRecords @infoTableName, 1, @whereClause, @fieldValueTrios, @lknServerName, @sourceDB;
		end

		--Insert the newKey - will be needed while inserting maps
		insert into #Tmp_Tbl values(@nodeKey, @nodeType, @parentkey, @parentType, @newKey);

		--We need to return the nodeKey of the pport/program
		if (@sNodeKey=@nodeKey and @sNodeType=@nodeType) set @retKey=@newKey;

		fetch next from MyCursor into @nodeKey, @nodeType, @parentkey, @parentType;
	end
	close MyCursor;
	deallocate MyCursor;

	create table #TMP_CHKPASTELNK(NodeKey int,NodeType int)

	declare curs2 cursor fast_forward for select NodeKey,NodeType,ParentKey,ParentType from #TMPTREE order by NodeKey,NodeType;
	open curs2
	fetch next from curs2 into  @nodeKey, @nodeType, @parentkey, @parentType;
	while @@fetch_status = 0
	begin
		set @newParentKey=1;
	 	select @newKey = NewNodeKey from #Tmp_Tbl where NodeKey=@nodeKey and NodeType=@nodeType;
	 	select @newParentKey = NewNodeKey from #Tmp_Tbl where NodeKey=@parentKey and NodeType=@parentType;

	 	if (@nodeType=0)
	 	begin--folder
	 		if not exists (select 1 from Fldrmap where Folder_Key=@newParentKey and Child_Key=@newKey and Child_Type=0)
	 			insert into Fldrmap(Folder_Key,Child_Key,Child_Type) values (@newParentKey,@newKey,0);
	 	end
		else if (@nodeType=1)
		begin--aport
			if @parentType=0
			begin
				if not exists (select 1 from Fldrmap where Folder_Key=@newParentKey and Child_Key=@newKey and Child_Type=@nodeType)
				begin
					insert into Fldrmap(Folder_Key,Child_Key,Child_Type) values (@newParentKey,@newKey,@nodeType);
					--Migrate Aport Parts--
					--Only if node has not been processed for paste link
					if not exists(select 1 from #TMP_CHKPASTELNK where NodeKey=@nodeKey and NodeType=@nodeType)
					begin
						exec absp_Migr_AportParts @nodeKey,@newKey,@lknServerName,@sourceDB;
					end
				end
			end
	 		else
	 		begin
	 			if not exists (select 1 from Aportmap where Aport_Key=@newParentKey and Child_Key=@newKey and Child_Type=@nodeType)
	 			begin
	 				insert into Aportmap(Aport_Key,Child_Key,Child_Type) values (@newParentKey,@newKey,@nodeType);
					--Migrate Aport Parts--
					--Only if node has not been processed for paste link
					if not exists(select 1 from #TMP_CHKPASTELNK where NodeKey=@nodeKey and NodeType=@nodeType)
					begin
						exec absp_Migr_AportParts @nodeKey,@newKey,@lknServerName,@sourceDB;
					end
	 			end
	 		end

	 	end
	 	else if (@nodeType=2)
	 	begin--pport
	 		if @parentType=0
	 		begin
				if not exists (select 1 from Fldrmap where Folder_Key=@newParentKey and Child_Key=@newKey and Child_Type=@nodeType)
					insert into Fldrmap(Folder_Key,Child_Key,Child_Type) values (@newParentKey,@newKey,@nodeType);
			end
			else
			begin
	 			if not exists (select 1 from Aportmap where Aport_Key=@newParentKey and Child_Key=@newKey and Child_Type=@nodeType)
	 				insert into Aportmap(Aport_Key,Child_Key,Child_Type) values (@newParentKey,@newKey,@nodeType);

	 		end
	 	end
	 	else if (@nodeType=23)
	 	begin--rport
	 		if @parentType=0
	 		begin
				if not exists (select 1 from Fldrmap where Folder_Key=@newParentKey and Child_Key=@newKey and Child_Type=@nodeType)
					insert into Fldrmap(Folder_Key,Child_Key,Child_Type) values (@newParentKey,@newKey,@nodeType);
			end
			else
			begin
	 			if not exists (select 1 from Aportmap where Aport_Key=@newParentKey and Child_Key=@newKey and Child_Type=@nodeType)
	 				insert into Aportmap(Aport_Key,Child_Key,Child_Type) values (@newParentKey,@newKey,@nodeType);
	 		end
	 	end
	 	else if (@nodeType=27)
	 	begin--prog
	 		if not exists (select 1 from Rportmap where Rport_Key=@newParentKey and Child_Key=@newKey and Child_Type=@nodeType)
	 		begin
	 			insert into Rportmap(Rport_Key,Child_Key,Child_Type) values (@newParentKey,@newKey,@nodeType);
				--Migrate Program parts
				--Only if node has not been processed for paste link
				if not exists(select 1 from #TMP_CHKPASTELNK where NodeKey=@nodeKey and NodeType=@nodeType)
				begin
					exec absp_Migr_ProgramParts @nodeKey,@newKey,@lknServerName,@sourceDB;
				end
	 		end
	 	end
	 	if (@nodeType=30)
	 	begin--case
	 		update caseInfo set Prog_Key=@newParentKey where case_Key=@newKey and Prog_Key=@parentKey;
	 		--Migrate Case parts
			exec absp_Migr_CaseParts @nodeKey,@newKey,@lknServerName,@sourceDB;
	 	end

	 	--Insert RtroMap--
		if not exists(select 1 from #TMP_CHKPASTELNK where NodeKey=@nodeKey and NodeType=@nodeType)
		begin
	 		if (@nodeType=2 or @nodeType=23)
	 		begin
	 			set @sql='update ' + @lknServerName+'.[' + @sourceDB + '].dbo.rtromap set Child_Type=23 where Child_Type=3 and Child_aply=' + cast(@nodeKey as varchar(20))
	 			exec (@sql)
	 			 --Update RetoKeys
	 			 truncate table #TMP_RTROKEYS
	 			 set @sql =  'insert into #TMP_RTROKEYS (OldRtroKey,NewRtroKey)
	 		  		select A.Rtro_Key,B.Rtro_Key from '+ @lknServerName+'.[' + @sourceDB + '].dbo.RtroInfo A inner join RtroInfo B
	 		  		on A.LongName=B.LongName COLLATE SQL_Latin1_General_CP1_CI_AS'
	 			 exec(@sql)


	 			 set @sql =  'insert into RTROMAP(Rtro_key,Child_Aply,Child_Type)
	 		 			select B.NewRtroKey,' + cast(@newKey as varchar(20)) +',Child_Type
	 		 			from '+ @lknServerName+'.[' + @sourceDB + '].dbo.Rtromap A inner join #TMP_RTROKEYS B
	 		 			on A.Rtro_Key=B.OldRtroKey
	 					and Child_aply=' + cast(@nodeKey as varchar(20)) + ' and Child_Type=' + cast(@nodeType as varchar(20))
	 			begin try
					exec(@sql)
				end try
				begin catch
					--Exception of duplicate key during paste linked nodes
				end catch
				truncate table #TMP_RTROKEYS
			end

		end
		insert into #TMP_CHKPASTELNK values(@nodeKey,@nodeType)
		fetch next from curs2 into @nodeKey, @nodeType, @parentkey, @parentType;
	end
	close curs2;
	deallocate curs2;

	return @retKey;
end
