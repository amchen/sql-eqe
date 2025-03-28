if exists(select * from sysobjects where id = object_id(N'absp_MoveDoneDatesBack') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_MoveDoneDatesBack
end
go
create procedure absp_MoveDoneDatesBack @origDate char(8) = '',@daysBack int = 30,@debug int = 0 

/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    SQL2005
Purpose:       This procedures subtract days using parameter daysBack from origDate which is the value 
	       of datefield of table.
     
    	    
Returns:       Nothing 

====================================================================================================
</pre>
</font>
##BD_END 

##PD  @origDate ^^  The original date which is stroed in date field
##PD  @daysBack ^^  The number of days to be backed from origDate
##PD  @debug ^^  A flag to determine whether message will be displayed or not

*/
as
begin
declare @tableName varchar(1000)
declare @fieldName varchar(1000)
declare @msg varchar(2000)

exec absp_MessageEx 'absp_MoveDoneDatesBack start'

declare curs_dictcol cursor fast_forward for
	select distinct ltrim(rtrim(TABLENAME)) as TN, ltrim(rtrim(FIELDNAME)) as FN 
		from DICTCOL where
		FIELDTYPE = 'C' and FIELDWIDTH = 14 and
		(TABLENAME like '%DONE%' or TABLENAME = 'LOGS' )
		order by TN, FN
open curs_dictcol
fetch next from curs_dictcol into @tableName, @fieldName
while @@fetch_status = 0
begin
	if @debug > 0 
    begin
        set @msg = @tableName + ', ' + @fieldName
		exec absp_MessageEx @msg
    end
	exec absp_MoveDoneDatesBackSubr  @tableName, @fieldName, @origDate, @daysBack, @debug 
	fetch next from curs_dictcol into @tableName, @fieldName
end 
close curs_dictcol
deallocate curs_dictcol

end