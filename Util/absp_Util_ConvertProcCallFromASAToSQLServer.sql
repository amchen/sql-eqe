if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_ConvertProcCallFromASAToSQLServer') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Util_ConvertProcCallFromASAToSQLServer
end
 go

create procedure absp_Util_ConvertProcCallFromASAToSQLServer @sqlSrvProcCall varchar(max) output, @asaProcCall varchar(max)

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure converts a procedure call query for ASA to SQL Server.

Returns:       Nothing

=================================================================================
</pre>
</font>
##BD_END

##PD  @sqlSrvProcCall  ^^ (OUTPUT PARAM)Converted procedure call for SQL Server.
##PD  @asaProcCall ^^ ASA procedure call.
*/

as

begin
 
   set nocount on
	declare @tmpIndx int

	set @asaProcCall = rtrim(@asaProcCall)
	
	if(left(@asaProcCall, 4) <> 'call')
	begin
		set @sqlSrvProcCall = @asaProcCall
		return
	end
	 -- replace call with exec
    set @sqlSrvProcCall = 'exec' + right(@asaProcCall, len(@asaProcCall) - 4)
	
	-- remove first occurrence of '('
	set @tmpIndx = CHARINDEX('(', @sqlSrvProcCall) 
	set @sqlSrvProcCall = left(@sqlSrvProcCall, @tmpIndx - 1) + ' '+ substring(@sqlSrvProcCall, @tmpIndx + 1, len(@sqlSrvProcCall))
	
	-- remove last occurrence last ')'
	set @sqlSrvProcCall = left(@sqlSrvProcCall, len(@sqlSrvProcCall) - (CHARINDEX(')', REVERSE(@sqlSrvProcCall)))) 
       
end



