if exists(select * from SYSOBJECTS where ID = object_id(N'absp_HostedAccount_UsageReportYearEnd') and objectproperty(ID,N'isprocedure') = 1)
begin
 drop procedure absp_HostedAccount_UsageReportYearEnd
end
go

create procedure absp_HostedAccount_UsageReportYearEnd
	@year char(4)
as	
/* 
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose: 

The procedure returns the report for a given years usage.

Examples:
	exec absp_HostedAccount_UsageReportYearEnd '2013'

Returns:       Resultset.

=================================================================================
</pre> 
</font> 
##BD_END 

##PD  @year ^^ A 4-char year of interest.  A blank will return all years.
##PD  @inputString ^^ comma+space separated list of field names.
##PD  @fieldValueTrios  ^^ Delimited string containing three fields for each substitution request.

*/
begin

			select HA.HostedAccountKey, substring(RequestDate, 1, 4) as ReportYear, substring(RequestDate, 5, 2) as ReportMonth,
				URI, CountryCode, PerilCode, SUM(NumberOfStructures) as TotalStructures 
			from HostedAccountUsage HAU
			inner join HostedAccount HA on HAU.HostedAccountKey = HA.HostedAccountKey
			where left(RequestDate, 4) = @year or LEN(RequestDate) = 8 - LEN(@year)
			group by HA.HostedAccountKey, substring(RequestDate, 1, 4),substring(RequestDate, 5, 2), HostedAccountName, URI, CountryCode, PerilCode
			order by 2,3,1,4, 5, 6 desc;

end
