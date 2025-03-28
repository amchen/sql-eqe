if exists(select * from SYSOBJECTS where ID = object_id(N'absp_InvalidateHelperGetNegativeCaseKey') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_InvalidateHelperGetNegativeCaseKey
end
go

create procedure absp_InvalidateHelperGetNegativeCaseKey
	@tableName varchar(120),
	@caseKey int

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MS SQL Server
Purpose:

This procedure returns a negative CASE_KEY that is inserted in the specified table when the table (Aportfolio related
table having Analysis Configuration Key)has no records or the minimum value of CASE_KEY in the table is <= 0.



Returns:       Returns the negative Case key
====================================================================================================
</pre>
</font>
##BD_END

##PD  @tableName ^^  Table name which is to be checked.
##PD  @caseKey ^^  The CASE_KEY for which we want to get a negative CASE_KEY.

##RD  @ret_minCaseKey ^^  Returns the negative Case key

*/
AS
begin

	set nocount on

	declare @ret_minCaseKey int
	declare @alreadyExists int
	declare @sql varchar(max)
	declare @sqln nvarchar(4000)

	Begin Try
		-- get the min key
		set @sqln = 'SELECT @ret_minCaseKey = min ( CASE_KEY ) FROM ' + @tableName
		execute sp_executesql @sqln, N'@ret_minCaseKey int OUTPUT', @ret_minCaseKey OUTPUT

		-- if null, set to -1
		set @ret_minCaseKey = coalesce (@ret_minCaseKey, -1)

		if @ret_minCaseKey <> 0
		begin
			if @ret_minCaseKey > 0
			begin
				-- just negate yourself
				set @ret_minCaseKey = -@caseKey
			end
			else
			begin
				set @alreadyExists = 1
				while(@alreadyExists <> 0)
				begin
					-- 1 less than current min
					set @ret_minCaseKey = @ret_minCaseKey - 1
					set @sql = 'INSERT INTO ' + @tableName +
					           ' (CASE_KEY, ANLCFG_KEY) VALUES (' + rtrim(ltrim(str(@ret_minCaseKey))) + ', 0 )'
					exec @alreadyExists = absp_Util_SafeExecSQL @sql, 1
				end
			end
		end
		return @ret_minCaseKey
	End Try

	Begin Catch
		-- Table Does Not Exists Or any other error --
		Print Error_Message()
		return 0		-- Only when for non existing @tableName
	End Catch

end