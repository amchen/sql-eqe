if exists(select * from SYSOBJECTS where ID = object_id(N'absp_HostedAccount_CreateAccount') and objectproperty(ID,N'isprocedure') = 1)
begin
 drop procedure absp_HostedAccount_CreateAccount
end
go

create procedure absp_HostedAccount_CreateAccount
	@hostedAccountName char(120),
	@priviledgeLevel int, 
	@inceptionDate char(8), 
	@expirationDate char(8),
	@detailXml varchar(max)
as
/* 
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose: 

The procedure creates a new hosted account.

Example
	exec absp_HostedAccount_CreateAccount 'New Acct Name', 1, '20130101', '20301231', ''

Returns:       Nothing.

=================================================================================
</pre> 
</font> 
##BD_END 

##PD  @hostedAccountName ^^ The name of the hosted account to update.
##PD  @priviledgeLevel ^^ The priviledge level for the account.
##PD  @inceptionDate  ^^ 8-char date string specifying when this account becomes active.
##PD  @expirationDate  ^^ 8-char date string specifying when this account expires.
##PD  @detailXml  ^^ An XML string that gives additional information interpreted by the utility.

*/
begin
	declare @hostedAccountID int;
	
	select @hostedAccountID = HostedAccountKey  from HostedAccount where HostedAccountName = @hostedAccountName;
	if @hostedAccountID is null
		insert into HostedAccount(HostedAccountName, PriviledgeLevel, InceptionDate, ExpirationDate, DetailsXml)
			values(@hostedAccountName, @priviledgeLevel, @inceptionDate, @expirationDate, @detailXml);
			
	-- Hibernate requires the return of something or a nullException is thrown during Query.List
	select @@IDENTITY;
end
