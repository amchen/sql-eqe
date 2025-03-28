if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_DropEmptyTablesFromArcCan') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_DropEmptyTablesFromArcCan
end

go
create procedure absp_Migr_DropEmptyTablesFromArcCan  
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

      		   This procedure was created as a fix for defect SDG__00023248. Since the migration process 
      		   unloads all tables in the Archive Can, unneeded tables are dropped after migration completes.
  
Returns:       Nothing
====================================================================================================
</pre>
</font>
##BD_END 

*/
as
begin
set nocount on

declare @sql varchar(max)
declare @tname varchar(200)
declare @cnt int

--Drop tables that are not needed during Archive--
declare  curs1 cursor for
    select TABLENAME  from DICTTBL T1, SYS.TABLES T2
				where T1.TABLENAME=T2.NAME and T1.ARC_CATGRY = 'NA'
open curs1
fetch curs1 into @tname
while @@fetch_status=0
begin
    execute( 'drop table ' + @tname)
	fetch curs1 into @tname
end 
close curs1
deallocate curs1

--Drop empty tables--
declare  curs2 cursor for
   select  TABLENAME as TN2  from DICTTBL T1, SYS.TABLES T2
				where T1.TABLENAME=T2.NAME 
open curs2
fetch curs2 into @tname
while @@fetch_status=0
begin
	select @cnt= ROWCNT from SYS.SYSINDEXES where object_name(ID)= @tname and INDID<2
	if @cnt=0
      execute( 'drop table ' + @tname)
    fetch curs2 into @tname
end
close curs2
deallocate curs2

end 
