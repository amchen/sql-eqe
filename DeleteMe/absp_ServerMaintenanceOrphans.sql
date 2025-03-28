if exists(select * FROM SYSOBJECTS WHERE id = object_id(N'absp_ServerMaintenanceOrphans') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_ServerMaintenanceOrphans
end
go

create procedure --=================================================
absp_ServerMaintenanceOrphans as
/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    	MSSQL
Purpose:	This procedure calls absp_ServerMaintenanceChasOrphans() to delete all the records from
CHASDATA having the CHAS_KEY which does not exist in CHASINFO table.

Returns:	Nothing

====================================================================================================

</pre>
</font>
##BD_END

*/
begin
 
   set nocount on
   
  
   print convert(varchar,GetDate(),100)+' inside absp_ServerMaintenanceOrphans '
   execute absp_ServerMaintenanceChasOrphans
--=================================================
end



