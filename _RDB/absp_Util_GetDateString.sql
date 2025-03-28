if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_GetDateString') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetDateString
end
go

create procedure absp_Util_GetDateString
	@ret_Date char(25) output,
	@formatString char(40) = 'yyyymmddhhnnss',
	@userDate datetime = NULL
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    SQL2005
Purpose:

This procedure returns the current or user provided datetime in the specified format in an out parameter.

Returns:       Nothing
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @ret_Date		 ^^	An OUTPUT parameter that holds the current date and/or time in the specified format.
##PD  @formatString  ^^ The format string is based on which the current date is to be formatted.
##PD  @userDate 	 ^^ User provided date for formatting. Default is current date if not provided.
*/
as
begin	
	set nocount on   
	declare @retString char(25)
	declare @currDateTime datetime
	declare @currDateString varchar(40)
	declare @currYear varchar(10)
	declare @currMonth varchar(10)
	declare @currDay varchar(10)
	declare @currHour varchar(10)
	declare @currMins varchar(10)
	declare @currSecs varchar(10)
	declare @currMiliSecs varchar(10)
	declare @currAMPM varchar(2)
	declare @curMonthName varchar(15)
	declare @curFullMonthName varchar(15)
	
	if @userDate is NULL
		set @currDateTime = GetDate()
	else
		set @currDateTime = @userDate
	
	set @currDateString =   convert(varchar(40), @currDateTime, 109)
	set @currYear		=	year(@currDateTime)
	set @currMonth		=	right('0'  + cast(month(@currDateTime) as varchar(2)), 2)
	set @currDay		=	right('0'  + cast(day(@currDateTime) as varchar(2)), 2)
	set @currHour		=	right('0'  + cast(datepart(hour, @currDateTime) as varchar(2)), 2)
	set @currMins		=	right('0'  + cast(datepart(minute, @currDateTime) as varchar(2)), 2)
	set @currSecs		=	right('0'  + cast(datepart(second, @currDateTime) as varchar(2)), 2)
	set @currMiliSecs	=	right('00' + cast(datepart(millisecond, @currDateTime) as varchar(3)), 3)
	set @currAMPM		=	right(@currDateString, 2)
	set @curMonthName	=	substring(@currDateString, 1, charindex(' ', @currDateString) - 1)
	set @curFullMonthName = datename(month, @currDateTime)

	if @formatString = 'yyyymmddhhnnss'
	begin
		if @currAMPM = 'PM' and @currHour < 12
		begin					
			set @currHour = @currHour + 12
		end
		set @retString = @currYear + @currMonth + @currDay + @currHour + @currMins + @currSecs
	end
	else if @formatString = '_yyyy-mm-dd_hh-nn-ss_'
	begin
		if @currAMPM = 'PM' and @currHour < 12
		begin
			set @currHour = @currHour + 12
		end
		set @retString = '_'+@currYear + '-' + @currMonth + '-' + @currDay
		set @retString = ltrim(rtrim(@retString)) + '_' + @currHour + '-' + @currMins + '-' + @currSecs + '_'
	end
	else if @formatString = 'yyyy/mm/dd hh:nn:ss'
	begin
		if @currAMPM = 'PM' and @currHour < 12
		begin					
			set @currHour=	@currHour + 12
		end
		set @retString = @currYear +  '/' + @currMonth +  '/' + @currDay
		set @retString = ltrim(rtrim(@retString)) + ' ' + @currHour +  ':' + @currMins +  ':' + @currSecs
	end
	else if @formatString = 'yyyy/mm/dd hh:nn:ss[sss]'
	begin
		if @currAMPM = 'PM' and @currHour < 12
		begin					
			set @currHour = @currHour + 12
		end
		set @retString = @currYear + '/' + @currMonth + '/' + @currDay 
		set @retString = ltrim(rtrim(@retString)) + ' ' + @currHour + ':' + @currMins + ':' + @currSecs + '[' + @currMiliSecs + ']'
	end
	else
	begin
		if @formatString = 'yyyymmdd'
		begin
			set @retString = @currYear + @currMonth + @currDay
		end
		else
		begin
			if @formatString = 'hhnnss'
			begin
				if @currAMPM = 'PM' and @currHour < 12
				begin
					set @currHour = @currHour + 12
				end
				set @retString = @currHour + @currMins + @currSecs
			end
			else if @formatString = 'hhnnss.sss'
			begin
				if @currAMPM = 'PM' and @currHour < 12
				begin					
					set @currHour = @currHour + 12
				end
				set @retString = @currHour + @currMins + @currSecs + @currMiliSecs				
			end	
			else
			begin
				if @formatString = 'Mmm dd yyyy hh:nnAA'
				begin
					set @retString = @curMonthName + ' ' + @currDay + ' ' + @currYear + ' ' +
					                 @currHour + ':' + @currMins + @currAMPM
				end
				else if @formatString = 'Mmmmmmmmm dd, yyyy hh:nn:ss'
				begin
					set @retString = @curFullMonthName + ' ' + @currDay + ', ' + @currYear + ' ' +
					                 @currHour + ':' + @currMins + ':' + @currSecs
				end
				else
				begin
					set @retString = ltrim(rtrim(@formatString))
				end
			end	
		end
	end	
	set @ret_Date = @retString
end
