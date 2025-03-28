if exists(select * from dbo.SYSOBJECTS where ID = object_id(N'dbo.absp_Util_CreateLinkedServer') and objectproperty(id,N'IsProcedure') = 1)
begin
	drop procedure dbo.absp_Util_CreateLinkedServer;
end
GO

create procedure [dbo].[absp_Util_CreateLinkedServer]
	@server Varchar (255),
	@dataSource varchar (255),
	@catalog varchar (255) = 'EQE'
as
-- This procedure creates a linked server, dropping an existing one, with the help of passed parameters --
-- Procedure returns 0 on success, 1 on failure & 2 when linked server already exists --
-- Precedure returns resultset in case of any error --
begin

	set nocount on;

	declare @tmpSql nvarchar(200);
	declare @provider varchar(200);
	declare @retVal int;
	declare @tmpRetVal nvarchar(10);

	set @retVal = 1;	-- initially set to failed value
	set @provider = 'SQLNCLI';

	begin try
		IF  NOT EXISTS (SELECT srv.name FROM sys.servers srv WHERE srv.server_id != 0 AND srv.name = '' + @server + '')
		--EXEC master.dbo.sp_dropserver  @server
			begin
				set @tmpSql = 'master.dbo.sp_addlinkedserver @server = N'''  + @server  + '''' + ', @srvproduct = ''''' + ' ,@provider=N''' + @provider + '''' + ', @datasrc=N''' + @dataSource + '''' + ', @catalog=''' + @catalog + ''''
				EXEC (@tmpSql)

				set @tmpSql = 'master.dbo.sp_serveroption @server = N'''  + @server  + '''' + ', @optname=N''' +  'collation compatible''' +  ', @optvalue=N''' + 'false'''
				EXEC (@tmpSql)

				set @tmpSql = 'master.dbo.sp_serveroption @server = N'''  + @server  + '''' + ', @optname=N''' +  'data access''' +  ', @optvalue=N''' + 'true'''
				EXEC (@tmpSql)

				set @tmpSql = 'master.dbo.sp_serveroption @server = N'''  + @server  + '''' + ', @optname=N''' +  'rpc''' +  ', @optvalue=N''' + 'true'''
				EXEC (@tmpSql)

				set @tmpSql = 'master.dbo.sp_serveroption @server = N'''  + @server  + '''' + ', @optname=N''' +  'rpc out''' +  ', @optvalue=N''' + 'true'''
				EXEC (@tmpSql)

				set @tmpSql = 'master.dbo.sp_serveroption @server = N'''  + @server  + '''' + ', @optname=N''' +  'connect timeout''' +  ', @optvalue=N''' + '0'''
				EXEC (@tmpSql)

				set @tmpSql = 'master.dbo.sp_serveroption @server = N'''  + @server  + '''' + ', @optname=N''' +  'collation name''' +  ', @optvalue=N''' + 'null'''
				EXEC (@tmpSql)

				set @tmpSql = 'master.dbo.sp_serveroption @server = N'''  + @server  + '''' + ', @optname=N''' +  'query timeout''' +  ', @optvalue=N''' + '0'''
				EXEC (@tmpSql)

				set @tmpSql = 'master.dbo.sp_serveroption @server = N'''  + @server  + '''' + ', @optname=N''' +  'use remote collation''' +  ', @optvalue=N''' + 'true'''
				EXEC (@tmpSql)

				-- Check by query if we are able to connect to linked server
				set @tmpSql = 'select @tmpRetVal = count(*) from '+ @server + '.' + @catalog + '.dbo.Sysobjects'
				Exec sp_ExecuteSql @tmpSql, N'@tmpRetVal nvarchar(10) output', @tmpRetVal output

				set @retVal = @tmpRetVal
				if @retVal > 0 set @retVal = 0 -- Linked server created successfully
			end
		else
			begin
				set @retVal = 2  -- Linked server already exists
			end
	end Try

	begin catch
		set @retVal = 1;	-- Failed to create Linked server or may be any other error
		Select Error_Number(), Error_Message();
	end catch

	return @retVal;
end
