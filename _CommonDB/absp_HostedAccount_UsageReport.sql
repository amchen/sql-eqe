if exists(select * from SYSOBJECTS where ID = object_id(N'absp_HostedAccount_UsageReport') and objectproperty(ID,N'isprocedure') = 1)
begin
 drop procedure absp_HostedAccount_UsageReport
end
go

create procedure absp_HostedAccount_UsageReport
	@year char(4),
	@month char(2),
	@detailed int = 0,
	@hostedAccoutName char(120) = ''
as
/* 
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose: 

The procedure gets either summary or details for all accounts or a given account.

Example
	exec absp_HostedAccount_UsageReport '2013', '08'
	exec absp_HostedAccount_UsageReport '2013', '08', 1
	exec absp_HostedAccount_UsageReport '2013', '08', 1, 'Some Acct Name'

Returns:       Resultset.

=================================================================================
</pre> 
</font> 
##BD_END 

##PD  @year ^^ A 4-char year of interest.  A blank will return all years.
##PD  @month ^^ A 2-char month of interest (01 - 12).
##PD  @detailed ^^ 0 for summary report; 1 for detailed report.
##PD  @hostedAccountName ^^ The name of the hosted account to report on - blank returns all.

*/	
begin
	if @detailed = 0 
		begin
			select @year as Year, @month as Month, HA.HostedAccountKey, HostedAccountName, CountryCode, PerilCode, SUM(NumberOfStructures) as TotalStructures from HostedAccountUsage HAU
			inner join HostedAccount HA on HAU.HostedAccountKey = HA.HostedAccountKey
			where left(RequestDate, 4) = @year and substring(RequestDate, 5, 2) = @month
			group by HA.HostedAccountKey, HostedAccountName, CountryCode, PerilCode
			order by 1,2,3,4;
		end
	else
		begin
			if LEN(@hostedAccoutName) = 0 
				begin
					select HA.HostedAccountKey, HostedAccountName, RequestDate, URI, CountryCode, PerilCode, NumberOfStructures from HostedAccountUsage HAU
					inner join HostedAccount HA on HAU.HostedAccountKey = HA.HostedAccountKey
					where left(RequestDate, 4) = @year and substring(RequestDate, 5, 2) = @month
					order by 1,2,3,4,5,6;
				end
			else
				begin
					select HA.HostedAccountKey, HostedAccountName, RequestDate, URI, CountryCode, PerilCode, NumberOfStructures from HostedAccountUsage HAU
					inner join HostedAccount HA on HAU.HostedAccountKey = HA.HostedAccountKey
					where left(RequestDate, 4) = @year and substring(RequestDate, 5, 2) = @month
					and HostedAccountName = @hostedAccoutName
					order by 1,2,3,4,5,6;
				end
		end
end




