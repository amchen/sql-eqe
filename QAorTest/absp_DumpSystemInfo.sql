if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_DumpSystemInfo') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_DumpSystemInfo
end
go

create procedure absp_DumpSystemInfo    @outputPath varchar(500), 
					@userName varchar(100) = '',
					@password varchar(100) = ''

/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL

Purpose:	   This procedure dumps lookup table data and system statistics in the given outputPath.

Returns: 	   Nothing

====================================================================================================
</pre>
</font>
##BD_END 

##PD  @outputPath ^^ The path to dump lookup table data
##PD  @userName ^^ The userName - in case of SQL authentication
##PD  @password ^^ The password - in case of SQL authentication

*/
as
begin
    
	exec absp_DumpSystemStats @outputPath, @userName, @password
	exec absp_DumpLookupTables @outputPath, @userName, @password
end
