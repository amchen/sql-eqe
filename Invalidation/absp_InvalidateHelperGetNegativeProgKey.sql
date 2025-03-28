if exists(select * from SYSOBJECTS where ID = object_id(N'absp_InvalidateHelperGetNegativeProgKey') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_InvalidateHelperGetNegativeProgKey
end
go

create  procedure absp_InvalidateHelperGetNegativeProgKey
	@tableName varchar(120),
	@progKey int,
	@programKey int=0

/*
##BD_BEGIN absp_InvalidateHelperGetNegativeProgKey ^^
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns a negative PROG_KEY that is inserted in the specified table when the table
(PROGRAM related table having Analysis Configuration Key)has no records or the minimum
value of PROG_KEY in the table is <= 0.

This procedure returns negative PROG_KEY for a given PROG_KEY from a given table when the table
has all positive PROG_KEY.

Returns:       Returns the negative Program key
====================================================================================================
</pre>
</font>
##BD_END

##PD  @tableName ^^  Table name which is to be checked.
##PD  @progKey ^^  The PROG_KEY for which we want to get a negative PROG_KEY.

##RD  @ret_minProgKey ^^  Returns the negative Program key.

*/
AS
begin

	set nocount on

	declare @ret_minProgKey int
	declare @alreadyExists int
	declare @sql varchar(max)
	declare @sqln nvarchar(4000)
	declare @progCol varchar(20)
	declare	@anlcfgCol varchar(20)
	
	Begin Try
	
		if (@programKey=1) --handle table column exceptions: i.e.ExpPolA,LimtPolA
			begin 
				set @progCol='PROGRAMKEY';
				set @anlcfgCol= 'ANLCFGKEY';
			end
		else
			begin 
				set @progCol='PROG_KEY'
				set @anlcfgCol= 'ANLCFG_KEY'
			end
		-- get the min key
		set @sqln = 'SELECT @ret_minProgKey = min ( '+@progCol+' ) FROM ' + @tableName
		execute sp_executesql @sqln, N'@ret_minProgKey int OUTPUT', @ret_minProgKey OUTPUT

		-- if null, set to -1
		set @ret_minProgKey = coalesce (@ret_minProgKey, -1)

		if @ret_minProgKey <> 0
		begin
			if @ret_minProgKey > 0
			begin
				-- just negate yourself
				set @ret_minProgKey = -@progKey
			end
			else
			begin
				set @alreadyExists = 1
				while(@alreadyExists <> 0)
				begin
					-- 1 less than current min
					set @ret_minProgKey = @ret_minProgKey - 1
					set @sql = 'INSERT INTO ' + @tableName +
					           ' ('+@progCol+', '+@anlcfgCol+') VALUES (' + rtrim(ltrim(str(@ret_minProgKey))) + ', 0 )'
					execute @alreadyExists = absp_Util_SafeExecSQL @sql, 1
				end
			end
		end
		return @ret_minProgKey
	End Try

	Begin Catch
		-- Table Does Not Exists Or any other error --
		Print Error_Message()
		return 0		-- Only when for non existing @tableName
	End Catch

end