if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_UserInfoTables') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_UserInfoTables
end
go

create procedure absp_Migr_UserInfoTables  @serverName varchar(500),@userName varchar(100)='',@password varchar(100)='',@debug int=0
as 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose: 	This procedure will load  UserInfo, UserGroups and UserGroupMem from WCe3.16 to RQE13.

		This will be run by CSG after RQE13 installation and prior to migrating WCe 3.16 databases..
  	    
Returns:	Nothing
                   
====================================================================================================
</pre>
</font>
##BD_END

##PD	@serverName ^^  ServerName\InstanceName of the 3.16 commondb DB
##PD	@userName ^^ The username of the server
##PD	@password ^^ The password of the sever

*/

begin

	set nocount on
	declare @lknServerName varchar(500);
	declare @uName varchar(25)
	declare @gName varchar(25)
	declare @userKey int
	declare @groupKey int
	declare @newUserKey int
	declare @newGroupKey int
	declare @status int
	declare @sSql nvarchar(max)
	declare @sql nvarchar(max)
	declare @instanceName varchar(500)
	
	--Get the instanceName
	if charindex('\',@serverName)<>0 
		set @instanceName=right(@serverName,len(@serverName)-charindex('\',@serverName))
	else
		set @instanceName=''
		
	--Create a link server to the WCe database.
	set @lknServerName='WCEDBSvr' ;
	
	begin try
		exec @status=absp_CreateLinkedServer @lknServerName,@serverName,@instanceName,'commondb',@userName,@password;
		if @status=1 return; --Error creating linked server
		exec absp_MessageEx  'Created Linked server';
	end try
	begin catch
		print ERROR_MESSAGE()
		return
	end catch
	
	set @sSql ='select User_Key,Group_Key from  '+ @lknServerName+'.commondb.dbo.UsrGpMem'	 
	exec('declare  c1 cursor global for ' + @sSql)
	open c1
	fetch c1 into @userKey,@groupKey
	while @@fetch_status=0
	begin

		--Add UserGrps row
		set @sql='select @gName=Group_Name from  '+ @lknServerName+'.commondb.dbo.UserGrps u where Group_Key=' + cast(@groupKey as varchar(20))
		execute sp_executesql @sql,N'@gName varchar(25) output',@gName output
		
		
		if not exists(select 1 from UserGrps where Group_Name=@gName)
		begin
			set @sql = ' insert into UserGrps(Group_Name,Grp_Read,Grp_Write,Grp_Dlete,Grp_Analz,Othr_Read,Othr_Write,Othr_Dlete,Othr_Analz,Max_Logins,Grp_Atach,Grp_Dtach,Othr_Atach,Othr_Dtach)' + 
					' select  Group_Name,Grp_Read,Grp_Write,Grp_Dlete,Grp_Analz,Othr_Read,Othr_Write,Othr_Dlete,Othr_Analz,Max_Logins,Grp_Atach,Grp_Dtach,Othr_Atach,Othr_Dtach
						from  '+ @lknServerName+'.commondb.dbo.UserGrps where Group_Name = ''' + @gName+''''
			if @debug=0 execute absp_MessageEx @sql;
			execute(@sql);
				
			if @@rowcount>0	select  @newGroupKey = IDENT_CURRENT ('UserGrps');
					
		end
		else
			select @newGroupKey= Group_Key  from commondb.dbo.UserGrps u where Group_Name=@gName
		
	 	--Add UserInfo row
		set @sql='select  @uName=User_Name from  '+ @lknServerName+'.commondb.dbo.UserInfo u where User_Key=' + cast(@userKey as varchar(20))
		execute sp_executesql @sql,N'@uName varchar(25) output',@uName output
		
		if not exists(select 1 from UserInfo where User_Name=@uName)
		begin
			set @sql = ' insert into UserInfo(User_Name,Password,Status,FirstName,LastName,Email_addr,Group_Key)' + 
						' select User_Name,Password,Status,FirstName,LastName,Email_addr,' + dbo.trim(cast(@newgroupKey as varchar(10)))+
						 	' from  '+ @lknServerName+'.commondb.dbo.UserInfo where User_Name = ''' + @uName + ''''
			if @debug=0 execute absp_MessageEx @sql;
			execute(@sql);
			
			if @@rowcount>0	select  @newUserKey = IDENT_CURRENT ('UserInfo');
			
		end		
		else
			select @newUserKey= User_Key  from commondb.dbo.UserInfo u where User_Name=@uName
		
		--Add UsrGpMem row--
		if not exists(select 1 from UsrGpMem where User_Key=@newUserKey   and Group_Key= @newGroupKey )
		begin
			begin try
				insert into UsrGpMem (User_Key,Group_Key)values(@newUserKey,@newGroupKey)
				if @debug=0  print 'Insert into UsrGpMem  UserKey=' + str(@newUserKey) + '  GrpKey=' + str( @newGroupKey)
			end try
			begin catch
				print ERROR_MESSAGE()
			end catch
		end
			
		fetch c1 into @userKey,@groupKey
	end 
	close c1
	deallocate c1
	
	--Drop linked server
	if exists(select 1 from master.sys.sysservers where srvName=@lknServerName)
	begin
		exec sp_dropserver @lknServerName, 'droplogins';
	end
end
	