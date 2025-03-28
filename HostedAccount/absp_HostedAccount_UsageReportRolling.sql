if exists(select * from SYSOBJECTS where ID = object_id(N'absp_HostedAccount_UsageReportRolling') and objectproperty(ID,N'isprocedure') = 1)
begin
 drop procedure absp_HostedAccount_UsageReportRolling
end
go

create procedure absp_HostedAccount_UsageReportRolling
	@year char(4),
	@month char(2)

as
/* 
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL 
Purpose: 

The procedure returns a year-over-year list for all accounts.

Examples
	exec absp_HostedAccount_UsageReportRolling '2013', '01'
	exec absp_HostedAccount_UsageReportRolling '2013', '12'

Returns:       Resultset.

=================================================================================
</pre> 
</font> 
##BD_END 

##PD  @year ^^ A 4-char year of interest.  A blank will return all years.
##PD  @month ^^ A 2-char month of interest (01 - 12).

*/	
begin

declare @betweenEnd int;
declare @betweenStart int;


set @betweenEnd = CAST(@year as int) * 12 + CAST(@month as int);
set @betweenStart = @betweenEnd - 23;

with months as (
    select 1 as mon union all select 2 union all select 3 union all select 4 union all
    select 5 as mon union all select 6 union all select 7 union all select 8 union all
    select 9 as mon union all select 10 union all select 11 union all select 12
   ),
    years as (	select 2011 as yr union all select 2012 union all select 2013 union all 
				select 2014 union all select 2015 union all select 2016 union all select 2017
   ),

    monthyears as (
     select yr, mon, yr*12+mon as yrmon
     from months cross join years
    ),
     accts as (
     select *
     from monthyears my cross join
          (select distinct HostedAccountKey from HostedAccount where HostedAccountKey > 1
          ) r
    )
select yrmon, yr, mon, A.HostedAccountKey, (case when sum(NumberOfStructures) is not null then sum(NumberOfStructures) else 0 end )as Invocations from accts A
left outer join HostedAccountUsage H on A.HostedAccountKey = h.HostedAccountKey
and A.yr = SUBSTRING(H.Requestdate, 1, 4) and A.mon = cast(SUBSTRING(H.Requestdate, 5, 2) as int)
where yrmon between @betweenStart and @betweenEnd
group by yrmon, yr, mon, A.HostedAccountKey
order by 4,1

end



