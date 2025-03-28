if exists(select * from SYSOBJECTS where ID = object_id(N'absp_ServerStartupCFIRDB') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_ServerStartupCFIRDB
end

go

create procedure 
absp_ServerStartupCFIRDB 
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

              This procedure is called to initialize the results database during the Results database startup.

Returns:       Nothing.

====================================================================================================
</pre>
</font>
##BD_END

*/
begin

   	set nocount on
	
	if exists (select 1 from sys.synonyms where name = 'MigrateLookupID')
		drop synonym MigrateLookupID;
   
	--=================================================
	-- Fixed Defect: SDG 12391
	-- Drop Index for some tables in Master Database
	-- execute absp_DropIndexFromDB 1 -- debug flag set to 1 for verbose.	

end
