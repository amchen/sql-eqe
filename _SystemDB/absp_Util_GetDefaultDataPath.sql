if exists(select * from SYSOBJECTS where id = object_id(N'absp_Util_GetDefaultDataPath') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetDefaultDataPath;
end
go

create procedure absp_Util_GetDefaultDataPath
	@mdfPath varchar(512) output,
	@ldfPath varchar(512) output

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose: This procedure returns the default data path for the MDF and LDF as output parameters.
Returns: Nothing
====================================================================================================
</pre>
</font>
##BD_END

##PD  mdfPath ^^  The default MDF path.
##PD  ldfPath ^^  The default LDF path.
*/
AS
begin

	set nocount on;

	begin try
		-- Adapted from http://blogs.technet.com/b/sqlman/archive/2009/07/20/tsql-script-determining-default-database-file-log-path.aspx

		-- Check if temp database exists
		IF EXISTS(SELECT 1 FROM [master].[sys].[databases] WHERE [name] = 'zzRQETempDBForDefaultPath')
		BEGIN
			DROP DATABASE [zzRQETempDBForDefaultPath];
		END;

		-- Create temp database. Because no options are given, the default data and --- log path locations are used
		CREATE DATABASE zzRQETempDBForDefaultPath;

		--Get the default data path
		SELECT @mdfPath =
		(	SELECT LEFT(physical_name,LEN(physical_name)-CHARINDEX('\',REVERSE(physical_name))+1)
			FROM sys.master_files mf
			INNER JOIN sys.[databases] d
			ON mf.[database_id] = d.[database_id]
			WHERE d.[name] = 'zzRQETempDBForDefaultPath' AND type = 0);

		--Get the default Log path
		SELECT @ldfPath =
		(   SELECT LEFT(physical_name,LEN(physical_name)-CHARINDEX('\',REVERSE(physical_name))+1)
			FROM sys.master_files mf
			INNER JOIN sys.[databases] d
			ON mf.[database_id] = d.[database_id]
			WHERE d.[name] = 'zzRQETempDBForDefaultPath' AND type = 1);

		-- Clean up. Drop the temp database
		IF EXISTS(SELECT 1 FROM [master].[sys].[databases] WHERE [name] = 'zzRQETempDBForDefaultPath')
		BEGIN
			DROP DATABASE [zzRQETempDBForDefaultPath];
		END;
	end try
	begin catch
		set @mdfPath = 'Exception encountered';
		set @ldfPath = 'Exception encountered';
	end catch

	select @mdfPath as DefaultMDFPath, @ldfPath as DefaultLDFPath;

end

/*
declare @mdfPath varchar(512);
declare @ldfPath varchar(512);
exec absp_Util_GetDefaultDataPath @mdfPath output, @ldfPath output;
*/
