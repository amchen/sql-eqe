if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CreateLinkedServer') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure absp_CreateLinkedServer;
end
go

create procedure  absp_CreateLinkedServer
	@lknServerName varchar(100),
	@serverName varchar(130),
	@instanceName varchar(200),
	@catalog varchar(200)='',
	@userName varchar(100)='',
	@password varchar(100)=''
as

/*
##BD_begin
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================

Purpose:	This procedure will create a linked server.

Returns:	Nothing

====================================================================================================
</pre>
</font>
##PD  @exposureKey ^^ The exposureKey
##BD_END
*/
begin
	declare @svrName varchar(120)
	declare @sql nvarchar(max)
	declare @cnt int
	declare @majorVersion int
	declare @providerName nvarchar(10)

	--set ServerName+\InstanceName
	if charindex('\',@serverName)=0  and dbo.trim(@instanceName)<>''
		set @svrName=dbo.trim(@serverName) + '\'+dbo.trim(@instanceName)
	else
		set @svrName=dbo.trim(@serverName)

	--Drop linked server if already exists
	if exists(select 1 from master.sys.sysservers where srvName=@lknServerName) exec sp_dropserver @lknServerName, 'droplogins'
	
	--create linked server
	begin try

		set @majorVersion = CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') as nvarchar(MAX)), CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') as nvarchar(MAX))) - 1) as int);
		set @providerName = 'SQLNCLI' + str(@majorVersion)
		EXEC master.dbo.sp_addlinkedserver @server = @lknServerName, @srvproduct=N'', @provider=@providerName, @datasrc=@svrName, @catalog=@catalog
		if len(dbo.trim(@userName))>0
			exec master.dbo.sp_addlinkedsrvlogin @rmtsrvname=@lknServerName,@useself=N'False',@locallogin=NULL,@rmtuser=@userName,@rmtpassword=@password
		else
			exec master.dbo.sp_addlinkedsrvlogin @rmtsrvname=@lknServerName,@useself=N'True',@locallogin=NULL


		exec master.dbo.sp_serveroption @server= @lknServerName, @optname=N'collation compatible', @optvalue=N'false'
		exec master.dbo.sp_serveroption @server= @lknServerName, @optname=N'data access', @optvalue=N'true'
		exec master.dbo.sp_serveroption @server= @lknServerName, @optname=N'rpc', @optvalue=N'true'
		exec master.dbo.sp_serveroption @server= @lknServerName, @optname=N'rpc out', @optvalue=N'true'
		exec master.dbo.sp_serveroption @server= @lknServerName, @optname=N'connect timeout', @optvalue=N'0'
		exec master.dbo.sp_serveroption @server= @lknServerName, @optname=N'collation name', @optvalue=N'null'
		exec master.dbo.sp_serveroption @server= @lknServerName, @optname=N'query timeout', @optvalue=N'0'
		exec master.dbo.sp_serveroption @server= @lknServerName, @optname=N'use remote collation', @optvalue=N'false'

		--test linked server--
		set @sql = 'select  @cnt=count(*) from '+ dbo.trim(@lknServerName) + '.master.dbo.Sysobjects'
		exec sp_ExecuteSql @sql, N'@cnt nvarchar(10) output', @cnt output
		return 0

	end try
	begin catch
		declare @err int
		declare @ErrorSeverity int
		declare @ErrorState int
		declare @ErrorMessage nvarchar(MAX)
		set @err=@@error
		 SELECT 
        @ErrorMessage = ERROR_MESSAGE(),
        @ErrorSeverity = ERROR_SEVERITY(),
        @ErrorState = ERROR_STATE();

		if @err=53 or  @err=65535
			raiserror( 99999, @ErrorSeverity, @ErrorState, 'Server or Instance Name is incorrect. Unable to connect to the external database.')
		else if @err = 18456
			raiserror (99999, @ErrorSeverity, @ErrorState, 'Login or password is incorrect unable to connect to the external database.')
		else
			raiserror (99999, @ErrorSeverity, @ErrorState, 'Unable to retrieve database information from the external database.')
		return 1
	end catch
end