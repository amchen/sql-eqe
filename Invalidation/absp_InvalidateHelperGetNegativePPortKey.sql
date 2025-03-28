if exists(select * from SYSOBJECTS where ID = object_id(N'absp_InvalidateHelperGetNegativePPortKey') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_InvalidateHelperGetNegativePPortKey
end
go

create procedure absp_InvalidateHelperGetNegativePPortKey
	@tableName varchar(120),
	@pPortKey int

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns a negative PPORT_KEY that is inserted in the specified table when the table
(Primary portfolio related tables having Analysis Configuration Key)has no records in an  OUt parameter.
This procedure  returns negative PPORT_KEY for a given PPORT_KEY from a given table when the table
has atleast one positive PPORT_KEY.

Returns:       Returns the negetive PPORT_KEY
====================================================================================================
</pre>
</font>
##BD_END

##PD  @tableName ^^  Table name which is to be checked.
##PD  @pPortKey ^^  The PPORT_KEY for which we want to get a negative PPORT_KEY.

##RD  @ret_minPPortKey     ^^ Returns the negetive PPORT_KEY.

*/
AS
begin try

	set nocount on

	declare @ret_minPPortKey int
	declare @alreadyExists int
	declare @sql varchar(max)
	declare @sqln nvarchar(4000)

	--Begin Try
		-- get the min key
		set @sqln = 'SELECT @ret_minPPortKey = min ( PPORT_KEY )  FROM ' + @tableName
		execute sp_executesql @sqln, N'@ret_minPPortKey int OUTPUT', @ret_minPPortKey OUTPUT

		-- if null, set to -1
		set @ret_minPPortKey = coalesce (@ret_minPPortKey, -1)

		if @ret_minPPortKey <> 0
		begin
			if @ret_minPPortKey > 0
			begin
				-- just negate yourself
				set @ret_minPPortKey = -@pPortKey
			end
			else
			begin
				set @alreadyExists = 1
				while(@alreadyExists <> 0)
				begin
					-- 1 less than current min
					set @ret_minPPortKey = @ret_minPPortKey - 1
					set @sql = 'INSERT INTO ' + @tableName +
					           ' (PPORT_KEY, ANLCFG_KEY) VALUES (' + rtrim(ltrim(str(@ret_minPPortKey))) + ', 0 )'
					execute @alreadyExists = absp_Util_SafeExecSQL @sql, 1
				end
			end
		end
		return @ret_minPPortKey
	--End Try

	--Begin Catch
	--	-- Table Does Not Exists Or any other error --
	--	Print Error_Message()
	--	return 0		-- Only when for non existing @tableName
	--End Catch

END TRY

BEGIN CATCH;
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
END CATCH;