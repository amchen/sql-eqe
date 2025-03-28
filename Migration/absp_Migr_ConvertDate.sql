if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_ConvertDate') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_ConvertDate
end

go

create  procedure ----------------------------------------------------------
absp_Migr_ConvertDate @ret_Date varchar(max) output,@theDate char(30) 
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return a string value in an OUTPUT parameter containing the date in the
format(YYYY-MM-DD hh:mm:ss) for a given date in MM/DD/YYYY hh:mm:ss or YYYYMMDDhhmmss format.


Returns: Nothing

====================================================================================================
</pre>
</font>
##BD_END 

##PD @ret_Date ^^ A string value containing the date in a legal Sybase ASA format.(OUTPUT PARAMETER)
##PD @theDate ^^  Any string value.


*/
AS
begin

   set nocount on
   
  --------------------------------------------------------------------------------------
  -- This function coverts a date in the MM/DD/YYYY hh:mm:ss or YYYYMMDDhhmmss format to
  -- a legal ASA Sybase format of YYYY-MM-DD hh:mm:ss.
  --------------------------------------------------------------------------------------
   declare @theDateStr varchar(max)
   declare @theStr varchar(max)
   declare @theNewDate varchar(max)
   declare @theYear char(4)
   declare @theMonth char(2)
   declare @theDay char(2)
   declare @theHour char(2)
   declare @theMin char(2)
   declare @theSec char(2)
   declare @theTime varchar(max)
   declare @pos int
  -- check if theDate has MM/DD/YYYY hh:mm:ss format
   set @pos = charindex('/',@theDate)
   if(@pos > 1 and @pos < 4)
   begin
    -- date format is invalid
      set @theMonth = substring(@theDate,1,@pos -1)
      set @theStr = substring(@theDate,@pos+1,len(@theDate) -@pos+1)
      set @pos = charindex('/',@theStr)
      set @theDay = substring(@theStr,1,@pos -1)
      set @theStr = substring(@theStr,@pos+1,len(@theStr) -@pos+1)
      set @theYear = substring(@theStr,1,4)
      set @theTime = substring(@theStr,5,len(@theStr) -4) 
      set @theDateStr = rtrim(ltrim(@theYear))+'-'+@theMonth+'-'+@theDay+' '+@theTime
      set @theDateStr = rtrim(ltrim(@theDateStr))
   end
   else
   begin
    -- date format does not contain slash char
      set @theDateStr = @theDate
   end
  -- check if @theDateStr has YYYYMMDDhhmmss format
   set @pos = charindex('-',@theDateStr)
   if(@pos = 0)
   begin
    -- date format is invalid
      set @theYear = substring(@theDateStr,1,4)
      set @theMonth = substring(@theDateStr,5,2)
      set @theDay = substring(@theDateStr,7,2)
      set @theHour = substring(@theDateStr,9,2)
      set @theMin = substring(@theDateStr,11,2)
      set @theSec = substring(@theDateStr,13,2)
      set @theNewDate = rtrim(ltrim(@theYear))+'-'+@theMonth+'-'+@theDay+' '+@theHour+':'+@theMin+':'+@theSec
      set @theNewDate = rtrim(ltrim(@theNewDate))
   end
   else
   begin
    -- date format is correct
      set @theNewDate = @theDateStr
   end
   set @ret_Date = @theNewDate
end



