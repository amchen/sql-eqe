if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_GetDatabaseContent') and objectproperty(ID,N'IsProcedure') = 1)
begin
	drop procedure absp_Migr_GetDatabaseContent;
end
go

create procedure absp_Migr_GetDatabaseContent
	@externalDatabaseServerName varchar(130)='',
	@externalDatabaseInstanceName varchar(200)='',
	@userName varchar(100)='',
	@password varchar(100)='',
	@databaseName varchar(200),
	@isLocalServer int=0

as
/*
##BD_begin
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================

Purpose:	The procedure connects to the external database and then get the list of child nodes for that database.

Returns:	 A list of NodeKey, NodeType, ParentNodeKey, ParentNodeType and LongName.


====================================================================================================
</pre>
</font>
##PD  @externalDatabaseServerName ^^ The remote serverName where the databases exists.
##PD  @externalDatabaseInstanceName ^^ The remote instanceName
##PD  @userName ^^ The userName of the remote server
##PD  @password ^^ The password  of the remote server
##PD  @databaseName ^^ The databaseName

##BD_END
*/
begin
	set nocount on;
	begin try

		declare @sql varchar(max);
		declare @sql2 varchar(max);
		declare @severCreated int;
		declare @tname varchar(50);
		declare @linkedServerName varchar(100);
		declare @topNodeKey int;

		create table #TMP_FOLDERKEY (nodekey int);
		set @linkedServerName='';

		--Create a link server to the external database.
		begin try
			if @isLocalServer<>1
			begin
				set @linkedServerName='LknSvrForMigration';
				exec @severCreated=absp_CreateLinkedServer @linkedServerName,@externalDatabaseServerName,@externalDatabaseInstanceName,@databaseName,@userName,@password;
				exec absp_MessageEx  'Created Linked server';
	 		end

	 		--Add square brackets--
			execute absp_getDBName @databaseName out, @databaseName;

	 		--Fixed defect 5565:: On the Migrate Portfolio dialog, the icons for 3.16 RPort and 3.16 RaPort are the same (3.16 RaPort icon)
	 		set @sql= 'if not exists (select 1 from ' + dbo.trim(@databaseName) +'.sys.tables where name= ''Migr_Fldrmap'')
	 					select * into ' +dbo.trim(@databaseName) + '.dbo.Migr_FldrMap from ' +dbo.trim(@databaseName) + '.dbo.FldrMap;'
	 		set @sql=@sql+'if not exists (select 1 from ' + dbo.trim(@databaseName) +'.sys.tables where name= ''Migr_AportMap'')
	 					select * into '+dbo.trim(@databaseName) + '.dbo.Migr_AportMap from ' +dbo.trim(@databaseName) + '.dbo.AportMap;'
	 		set @sql=@sql+'if not exists (select 1 from ' + dbo.trim(@databaseName) +'.sys.tables where name= ''Migr_RportMap'')
	 					select * into '  +dbo.trim(@databaseName) + '.dbo.Migr_RportMap from ' +dbo.trim(@databaseName) + '.dbo.RportMap;'
	 		set @sql=@sql+'if not exists (select 1 from ' + dbo.trim(@databaseName) +'.sys.tables where name= ''Migr_Proginfo'')
	 					select * into '+dbo.trim(@databaseName) + '.dbo.Migr_Proginfo from ' +dbo.trim(@databaseName) + '.dbo.Proginfo;'

	 		if @isLocalServer<>1
	 		begin
				set @sql=replace (@sql,'''','''''')
				set @sql='exec('''+@sql+''') at ' + @linkedServerName;
				--set @sql = REPLACE(@sql2, '@sql', @sql);
			end
			print @sql
			exec (@sql)

			--Need to exclude GOM  ony portfolios--
			--Create a temporary table in linked server to hold the GOM PORT_IDs
			set @tName='GOM_PORTID_'+dbo.trim(cast(@@SPID as varchar(20)))



			if @isLocalServer<>1
			begin
				set @sql='if exists (select 1 from ' + dbo.trim(@databaseName) +'.sys.tables where name= ''''' + @tName + ''''') drop table ' + @tName
				set @sql='execute ('''+@sql+''') at ' + @linkedServerName
			end
			else
				set @sql='if exists (select 1 from ' + dbo.trim(@databaseName) +'.sys.tables where name= ''' + @tName + ''') drop table ' + dbo.trim(@databaseName) + '.dbo.' + @tName
			print @sql
			exec (@sql)

			set @sql = 'create table ' + dbo.trim(@databaseName) +'.dbo.' + @tname +' (PortId int)'
			if @isLocalServer<>1
				set @sql='execute ('''+@sql+''') at ' + @linkedServerName
			print @sql
			exec (@sql)

			set @sql='insert into ' + dbo.trim(@databaseName) +'.dbo.'+ @tName +' select PORT_ID from ' + dbo.trim(@databaseName) +'.dbo.GPI where TRANS_ID=59'
			if @isLocalServer<>1
				set @sql='execute ('''+@sql+''') at ' + @linkedServerName
			print @sql
			exec (@sql)

			-- Get the EDB Node Key. Usually FOLDER_KEY = 1 is the top level node (i.e. NodeType = 12) but
			-- we found that in some of the customer databases the top level node is not FOLDER_KEY = 1.
			-- The best way to find the top level node is check if FOLDERINFO.CF_NODE_KEY > 0

			set @sql = 'select Folder_Key from ' + dbo.trim(@databaseName) + '..FldrInfo where FldrInfo.CURR_NODE=''Y'''

			if @isLocalServer<>1
			begin
				set @sql=replace (@sql,'''','''''')
				set @sql2 ='insert into #TMP_FOLDERKEY SELECT * FROM OPENQUERY(' + @linkedServerName + ', ''@sql'')';
				set @sql = REPLACE(@sql2, '@sql', @sql);
			end
			print '$$$$$$$$$$$$$$$$$'
			print @sql
			exec (@sql)
			select @topNodeKey = nodekey from #TMP_FOLDERKEY;



			set @sql='select folder_Key as NodeKey, 12 as NodeType, 0 ParentNodeKey,0 ParentNodeType, longname from ' +
					dbo.trim(@databaseName) + '..FldrInfo where Curr_Node = ''Y''
			union
			select FldrInfo.folder_Key, 0, Migr_FldrMap.Folder_Key, Case when Migr_FldrMap.Folder_Key = ' + cast(@topNodeKey as char) + ' then 12 else 0 end , longname from '+
					dbo.trim(@databaseName) + '..FldrInfo inner join ' + dbo.trim(@databaseName) + '..Migr_FldrMap on Migr_FldrMap.Child_Key = FldrInfo.Folder_Key and Migr_FldrMap.Child_Type = 0 where  Status = ''Active'' and FldrInfo.Curr_Node = ''N''
			union
			select Aport_key, 1, Migr_FldrMap.Folder_Key,Case when Migr_FldrMap.Folder_Key = ' + cast(@topNodeKey as char) + ' then 12 else 0 end, longname from ' +
					dbo.trim(@databaseName) + '..aprtInfo inner join  ' + dbo.trim(@databaseName) + '..Migr_FldrMap on Migr_FldrMap.Child_Key = AprtInfo.Aport_Key and Migr_FldrMap.Child_Type = 1 where  Status = ''Active''
			union
			select distinct pprtInfo.pport_key, 2, Migr_FldrMap.Folder_Key,Case when Migr_FldrMap.Folder_Key = ' + cast(@topNodeKey as char) + ' then 12 else 0 end, PprtInfo.longname from ' +
					dbo.trim(@databaseName) + '..pprtInfo inner join  ' + dbo.trim(@databaseName) + '..Migr_FldrMap on Migr_FldrMap.Child_Key = pprtInfo.pport_Key
					inner join ' + dbo.trim(@databaseName) + '..PportMap on PportMap.Pport_Key=PprtInfo.Pport_Key
					inner join ' + dbo.trim(@databaseName) + '..LportMap on PportMap.Child_Key=LportMap.Lport_Key
					and PportMap.Child_Type=8 and Migr_FldrMap.Child_Type = 2
					where  PprtInfo.Status = ''Active''
					and LportMap.Port_Id not in (select PortID from ' + dbo.trim(@databaseName) +'.dbo.' + @tName + ')
			union
			select distinct rprtInfo.rport_key, 3, Migr_FldrMap.Folder_Key,Case when Migr_FldrMap.Folder_Key = ' + cast(@topNodeKey as char) + ' then 12 else 0 end, RprtInfo.longname from ' +
					dbo.trim(@databaseName) + '..rprtInfo inner join  ' + dbo.trim(@databaseName) + '..Migr_FldrMap on Migr_FldrMap.Child_Key = rprtInfo.rport_Key
					inner join ' + dbo.trim(@databaseName) + '..Migr_RportMap on Migr_RportMap.Rport_Key=RprtInfo.Rport_Key
					inner join ' + dbo.trim(@databaseName) + '..Migr_ProgInfo on Migr_RportMap.Child_Key=Migr_Proginfo.Prog_Key
					inner join ' + dbo.trim(@databaseName) + '..LportMap on Migr_Proginfo.Lport_Key=LportMap.Lport_Key
					and Migr_Rportmap.child_type =7
					and Migr_FldrMap.Child_Type = 3 where  RprtInfo.Status = ''Active''
					and LportMap.Port_Id not in (select PortID from ' + dbo.trim(@databaseName) +'.dbo.' + @tName + ')
			union
			select distinct RprtInfo.rport_key, 23, Migr_Fldrmap.Folder_Key,Case when Migr_Fldrmap.Folder_Key = ' + cast(@topNodeKey as char) + ' then 12 else 0 end, RprtInfo.longname from ' +
					dbo.trim(@databaseName) + '..rprtInfo inner join  ' + dbo.trim(@databaseName) + '..Migr_Fldrmap on Migr_Fldrmap.Child_Key = rprtInfo.rport_Key
					inner join ' + dbo.trim(@databaseName) + '..Migr_RportMap on Migr_RportMap.Rport_Key=RprtInfo.Rport_Key
					inner join ' + dbo.trim(@databaseName) + '..Migr_ProgInfo on Migr_RportMap.Child_Key=Migr_Proginfo.Prog_Key
					inner join ' + dbo.trim(@databaseName) + '..LportMap on Migr_Proginfo.Lport_Key=LportMap.Lport_Key
					and Migr_Rportmap.child_type =27
					and Migr_FldrMap.Child_Type = 23 where  RprtInfo.Status = ''Active''
					and LportMap.Port_Id not in (select PortID from ' + dbo.trim(@databaseName) +'.dbo.' + @tName + ')
			union
			select distinct pprtInfo.pport_key, 2, Migr_AportMap.APort_Key,1, PprtInfo.longname from ' +
					dbo.trim(@databaseName) + '..pprtInfo inner join  ' + dbo.trim(@databaseName) + '..Migr_AportMap on Migr_AportMap.Child_Key = pprtInfo.pport_Key
					inner join ' + dbo.trim(@databaseName) + '..PportMap on PportMap.Pport_Key=PprtInfo.Pport_Key
					inner join ' + dbo.trim(@databaseName) + '..LportMap on PportMap.Child_Key=LportMap.Lport_Key
					and PportMap.Child_Type=8 and Migr_AportMap.Child_Type = 2
					where  PprtInfo.Status = ''Active''
					and LportMap.Port_Id not in (select PortID from ' + dbo.trim(@databaseName) +'.dbo.' + @tName + ')
			union
			select distinct RprtInfo.rport_key, 3, Migr_AportMap.APort_Key,1, RprtInfo.longname from ' +
					dbo.trim(@databaseName) + '..rprtInfo inner join  ' + dbo.trim(@databaseName) + '..Migr_AportMap on Migr_AportMap.Child_Key = rprtInfo.rport_Key
					inner join ' + dbo.trim(@databaseName) + '..Migr_RportMap on Migr_RportMap.Rport_Key=RprtInfo.Rport_Key
					inner join ' + dbo.trim(@databaseName) + '..Migr_ProgInfo on Migr_RportMap.Child_Key=Migr_Proginfo.Prog_Key
					inner join ' + dbo.trim(@databaseName) + '..LportMap on Migr_Proginfo.Lport_Key=LportMap.Lport_Key
					and Migr_Rportmap.child_type =7
					and Migr_AportMap.Child_Type = 3 where  RprtInfo.Status = ''Active''
					and LportMap.Port_Id not in (select PortID from ' + dbo.trim(@databaseName) +'.dbo.' + @tName + ')
			union
			select distinct RprtInfo.rport_key, 23, Migr_AportMap.APort_Key,1, RprtInfo.longname from ' +
					dbo.trim(@databaseName) + '..rprtInfo inner join ' + dbo.trim(@databaseName) + '..Migr_AportMap on Migr_AportMap.Child_Key = rprtInfo.rport_Key
					inner join ' + dbo.trim(@databaseName) + '..Migr_RportMap on Migr_RportMap.Rport_Key=RprtInfo.Rport_Key
					inner join ' + dbo.trim(@databaseName) + '..Migr_ProgInfo on Migr_RportMap.Child_Key=Migr_Proginfo.Prog_Key
					inner join ' + dbo.trim(@databaseName) + '..LportMap on Migr_Proginfo.Lport_Key=LportMap.Lport_Key
					and Migr_Rportmap.child_type =27
					and Migr_AportMap.Child_Type = 23 where  RprtInfo.Status = ''Active''
					and LportMap.Port_Id not in (select PortID from ' + dbo.trim(@databaseName) +'.dbo.' + @tName + ')
			union
			select distinct Migr_ProgInfo.prog_key, 7, Migr_RportMap.RPort_Key,3, Migr_ProgInfo.longname from ' +
					dbo.trim(@databaseName) + '..Migr_ProgInfo inner join  ' + dbo.trim(@databaseName) + '..Migr_RportMap on Migr_RportMap.Child_Key = Migr_Proginfo.prog_key and Migr_RportMap.child_type = 7
					inner join ' + dbo.trim(@databaseName) + '..LportMap on Migr_Proginfo.Lport_Key=LportMap.Lport_Key
					and LportMap.Port_Id not in (select PortID from ' + dbo.trim(@databaseName) +'.dbo.' + @tName + ')
			union
			select distinct Migr_Proginfo.Prog_key, 27, Migr_RportMap.RPort_Key,23, Migr_Proginfo.longname from ' +
					dbo.trim(@databaseName) + '..Migr_Proginfo inner join  ' + dbo.trim(@databaseName) + '..Migr_RportMap on Migr_RportMap.Child_Key = Migr_Proginfo.prog_key and Migr_RportMap.child_type = 27
					inner join ' + dbo.trim(@databaseName) + '..LportMap on Migr_Proginfo.Lport_Key=LportMap.Lport_Key
					and LportMap.Port_Id not in (select PortID from ' + dbo.trim(@databaseName) +'.dbo.' + @tName + ')'

			if @isLocalServer<>1
			begin
				set @sql=replace (@sql,'''','''''')
				set @sql2='SELECT * FROM OPENQUERY(' + @linkedServerName + ', ''@sql'')';
				set @sql = REPLACE(@sql2, '@sql', @sql);
			end
			exec absp_MessageEx @sql
			exec (@sql)

			if @isLocalServer<>1
			begin
				set @sql='if exists (select 1 from sys.tables where name= ''''' + @tName + ''''') drop table ' + @tName
				set @sql='execute ('''+@sql+''') at ' + @linkedServerName
			end
			else
				set @sql='if exists (select 1 from sys.tables where name= ''' + @tName + ''')  drop table ' + dbo.trim(@databaseName) + '.dbo.' + @tName
			exec(@sql)

			--Drop linked server
			if exists(select 1 from master.sys.sysservers where srvName=@linkedServerName)
				exec sp_dropserver @linkedServerName, 'droplogins'
		end try
		begin catch
			select -1 as NodeKey, -1 as NodeType, -1 as ParentNodeKey,-1 as ParentNodeType,'' as longname
			select ERROR_MESSAGE() as ErrorMessage
			return
		end catch

		select '' as ErrorMessage

	end try
	begin catch
		declare @ProcName varchar(100);
		select @ProcName=object_name(@@procid);
		exec absp_Util_GetErrorInfo @ProcName;

		set @sql='if exists (select 1 from '+ dbo.trim(@databaseName) + '.sys.tables where name= ''''' + @tName + ''''') drop table ' + @tName
		if @isLocalServer<>1
			set @sql='execute ('''+@sql+''') at LknSvrForMigration'
		exec(@sql)

		--Drop linked server
		if exists(select 1 from master.sys.sysservers where srvName=@linkedServerName)
				exec sp_dropserver @linkedServerName, 'droplogins'
	end catch
end