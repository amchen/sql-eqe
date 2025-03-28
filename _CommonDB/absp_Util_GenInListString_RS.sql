if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_GenInListString_RS') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GenInListString_RS
end
go

create procedure absp_Util_GenInListString_RS @sql varchar(8000) , @listType char(1) = 'N' 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console" >
====================================================================================================
DB Version:	MSSQL
Purpose:	This procedure returns a resultset containing all rows of output of a select query 
                concatenated in a single string separated by comma. 
    	    	
Returns:        A single/multiple resultset
                In case of external applications, the return value cannot be more than 8K. If the inList
                is more than 8K, the procedure splits the string and returns a multiple resultSet.
               
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @sql 	^^  Single column select query.
##PD  @listType 	^^  Default is 'N' for numeric list else other than 'N' (enclosed within single quotes)


*/

begin
	set nocount on

	declare @inList varchar(MAX)
	declare @tList  varchar(8000)
	declare @pos integer
	
	set @pos = 1
	set @inList = ''
	
	exec absp_Util_GenInListString @inList output, @sql, @listType 
		
	CREATE TABLE #TMP (ID int IDENTITY , INLIST varchar(8000) COLLATE SQL_Latin1_General_CP1_CI_AS) 
		        
	set @tList=substring (@inList,@pos,8000);
	while(@tlist<>'')
	begin
		set @pos = @pos + 8000;
		insert into #TMP (INLIST) values(@tList);
		set @tList=substring (@inList,@pos,8000);
	end 

	select INLIST from #TMP order by ID;
end 