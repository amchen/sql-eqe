if exists(select * from SYSOBJECTS where ID = object_id(N'absp_HostedAccount_GetAccount') and objectproperty(ID,N'isprocedure') = 1)
begin
 drop procedure absp_HostedAccount_GetAccount
end
go

create procedure absp_HostedAccount_GetAccount
	@hostedAccoutName char(120) = ''
as
/* 
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose: 

The procedure gets an existing hosted account.

Example
	exec absp_HostedAccount_GetAccount 'New Acct Name'

Returns:       1-row recordset that matches the input name; no rows if no match.

=================================================================================
</pre> 
</font> 
##BD_END 

##PD  @hostedAccountName ^^ The name of the hosted account to update.

*/
begin

	select * from HostedAccount
	where HostedAccountName = @hostedAccoutName

end

