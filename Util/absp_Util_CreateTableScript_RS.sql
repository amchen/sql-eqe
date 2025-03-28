if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_CreateTableScript_RS') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateTableScript_RS
end
go

create procedure absp_Util_CreateTableScript_RS 
	@baseTableName      varchar(120) ,  
    @newTableName       varchar(120) = '' ,
    @dbSpaceName        varchar(40) = '' ,
    @makeIndex      int = 0 ,
    @addDfltVal     int = 0 ,
    @autoKeyFlag    int = 0 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console" >
====================================================================================================
DB Version:	MSSQL
Purpose:	This procedure returns a resultset containing the create table script broken into varchar(8000)
			in each row. 
    	    	
Returns:        A single resultset
                In case of external applications, the return value cannot be more than 8K. If the return
                value is more than 8K, the procedure splits the string and returns a resultSet.
               
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @baseTableName    ^^ Base Table Name as Input Parameter
##PD  @newTableName ^^ New Table .Name as Input Parameter
##PD  @dbSpaceName  ^^ dbSpaceName as Input Parameter
##PD  @makeIndex    ^^ Whether To Include Create Index Script As Input Parameter
##PD  @addDfltVal   ^^ Whether To Add Default Value as Input Parameter
##PD  @autoKeyFlag  ^^ Whether To Add Auto Incremented Key as Input Parameter

##RD  Script		^^ Script for creating table

*/

begin
	set nocount on

	declare @ret_sqlScript varchar(MAX)
	declare @partScript  varchar(8000)
	declare @pos integer
	
	set @pos = 1
	
	exec absp_Util_CreateTableScript @ret_sqlScript output, @baseTableName, @newTableName, @dbSpaceName, @makeIndex, @addDfltVal, @autoKeyFlag  
		
	CREATE TABLE #TMP (ID int IDENTITY , SCRIPT varchar(8000) COLLATE SQL_Latin1_General_CP1_CI_AS) 
		        
	set @partScript=substring (@ret_sqlScript,@pos,8000);
	while(@partScript<>'')
	begin
		set @pos = @pos + 8000;
		insert into #TMP (SCRIPT) values(@partScript);
		set @partScript=substring (@ret_sqlScript,@pos,8000);
	end 

	select SCRIPT from #TMP order by ID;
end 