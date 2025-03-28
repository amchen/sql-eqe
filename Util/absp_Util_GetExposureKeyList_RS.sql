if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_GetExposureKeyList_RS') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GetExposureKeyList_RS
end
go

create procedure absp_Util_GetExposureKeyList_RS @nodeKey int, @nodeType int
as

/*

##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure will return a resultset containing the list of ExposureKeys as output parameter for a given nodeKey and nodeType.
		For APORT this will return all the ExposureKeys for the child RPORT, PPORT and RAP portfolios.
		 
Returns:	A single/multiple resultset
                In case of external applications, the return value cannot be more than 8K. If the inList
                is more than 8K, the procedure splits the string and returns a multiple resultSet.
               

====================================================================================================

</pre>
</font>

##BD_END

##PD   	@nodeKey  ^^ Node Identifier like, APORT_KEY, PPORT_KEY, RPORT_KEY, PROG_KEY
##PD   	@nodeType ^^ Value to identify the node type. Valid values are Accumulation = 1; 
					Primary Portfolio = 2; Reinsurance Portfolio = 3; 
					Reinsurance Account Portfolio = 23; 
			
*/

begin 

	declare @inList varchar(MAX)
	declare @tList  varchar(8000)
	declare @pos integer
	
	set @pos = 1
	set @inList = ''
	
	exec absp_Util_GetExposureKeyList @inList out, @nodeKey, @nodeType 
	
	CREATE TABLE #TEMP (ID int IDENTITY , INLIST varchar(8000) COLLATE SQL_Latin1_General_CP1_CI_AS) 
	        
	set @tList=substring (@inList,@pos,8000);
	while(@tlist<>'')
	begin
		set @pos = @pos + 8000;
		insert into #TEMP (INLIST) values(@tList);
		set @tList=substring (@inList,@pos,8000);
	end 

	select INLIST from #TEMP order by ID;

end
