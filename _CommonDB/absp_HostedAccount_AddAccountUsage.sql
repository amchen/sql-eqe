if exists(select * from SYSOBJECTS where ID = object_id(N'absp_HostedAccount_AddAccountUsage') and objectproperty(ID,N'isprocedure') = 1)
begin
 drop procedure absp_HostedAccount_AddAccountUsage
end
go

create procedure absp_HostedAccount_AddAccountUsage
	@hostedAccountName char(120),
	@countryCode char(3),
	@perilCode char(35),
	@numberOfStructures int,
	@uriClient char(255)
as
/* 
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose: 

The procedure adds a usage record to the hostedaccountusage table.

Example
	exec absp_HostedAccount_AddAccountUsage 'Some Acct Name', 'USA', 'TCWI', '1', '11.22.33.44'

Example 2	
	begin
	declare @retCode int
	exec @retCode = absp_HostedAccount_AddAccountUsage 'Some Acct Name', 'USA', 'TCWI', '1', '11.22.33.44'
	print @retCode
	end

Returns:       @@identity.

=================================================================================
</pre> 
</font> 
##BD_END 

##PD  @hostedAccountName ^^ The name of the hosted account to update.
##PD  @@countryCode ^^ The 3-char country code.
##PD  @@perilCode  ^^ The 8-char peril code.
##PD  @@numberOfStructures  ^^ The number of structures at this country/peril combination successfully analyzed.
##PD  @@uriClient  ^^ The URI of the client calling for traceability.

*/
begin
	declare @hostedAccountID int;
		
	select @hostedAccountID = HostedAccountKey  from HostedAccount where HostedAccountName = @hostedAccountName;
	if @hostedAccountID is null set @hostedAccountID = 0;
	
	insert into HostedAccountUsage (HostedAccountKey, RequestDate, CountryCode, PerilCode, NumberOfStructures, URI)
	   values(@hostedAccountID, REPLACE(REPLACE(REPLACE(CONVERT(VARCHAR(20), GETDATE(), 120), '-', ''), ':', ''), ' ', ''), @countryCode, @perilCode, @numberOfStructures, @uriClient)
	   
	return @@identity;
end
