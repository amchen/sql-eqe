if exists(select * from SYSOBJECTS where ID = object_id(N'absp_InvalidateHelperGetNegativeRPortKey') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_InvalidateHelperGetNegativeRPortKey
end
go

create procedure absp_InvalidateHelperGetNegativeRPortKey
	@tableName varchar(120),
	@rPortKey int

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns a negative RPORT_KEY ( in an OUT parameter) that is inserted in the specified table when the table
(Rportfolio related table having Analysis Configuration Key)has no records or the minimum
value of RPORT_KEY in the table is <= 0. It returns negative RPORT_KEY for a given RPORT_KEY from a given table when the table
has all positive RPORT_KEY.

Returns:       Returns the negative Rport key
====================================================================================================
</pre>
</font>
##BD_END

##PD  @tableName ^^  Table name which is to be checked.
##PD  @rPortKey ^^  The RPORT_KEY for which we want to get a negative RPORT_KEY.

##RD  @ret_minRPortKey 	^^  Returns the negative Rport key.

*/
AS
begin

	set nocount on

	declare @ret_minRPortKey int
	declare @alreadyExists int
	declare @sql varchar(max)
	declare @sqln nvarchar(4000)

	Begin Try
		-- get the min key
		set @sqln = 'SELECT @ret_minRPortKey = min ( RPORT_KEY )  FROM ' + @tableName
		execute sp_executesql @sqln,N'@ret_minRPortKey int OUTPUT', @ret_minRPortKey OUTPUT

		-- if null, set to -1
		set @ret_minRPortKey = coalesce (@ret_minRPortKey, -1)

		if @ret_minRPortKey <> 0
		begin
			if @ret_minRPortKey > 0
			begin
				-- just negate yourself
				set @ret_minRPortKey = -@rPortKey
			end
			else
			begin
				set @alreadyExists = 1
				while(@alreadyExists <> 0)
				begin
					-- 1 less than current min
					set @ret_minRPortKey = @ret_minRPortKey - 1
					set @sql = 'INSERT INTO ' + @tableName +
					           ' (RPORT_KEY, ANLCFG_KEY) VALUES (' + rtrim(ltrim(str(@ret_minRPortKey))) + ', 0 )'
					execute @alreadyExists = absp_Util_SafeExecSQL @sql, 1
				end
			end
		end
		return @ret_minRPortKey
	End Try

	Begin Catch
		-- Table Does Not Exists Or any other error --
		Print Error_Message()
		return 0		-- Only when for non existing @tableName
	End Catch

end