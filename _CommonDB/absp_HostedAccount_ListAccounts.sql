if exists(select * from SYSOBJECTS where ID = object_id(N'absp_HostedAccount_ListAccounts') and objectproperty(ID,N'isprocedure') = 1)
begin
 drop procedure absp_HostedAccount_ListAccounts
end
go

create procedure absp_HostedAccount_ListAccounts

as
/* 
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose: 

The procedure returns all the hosted accounts - name, inception, expiry.

Example
	exec absp_HostedAccount_ListAccounts

Returns:       Nothing.

=================================================================================
</pre> 
</font> 
##BD_END 


*/
begin

	select HostedAccountKey, HostedAccountName, PriviledgeLevel, InceptionDate, ExpirationDate, DetailsXml from HostedAccount
	order by 1;
end
