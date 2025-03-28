if exists(select * from SYSOBJECTS where ID = object_id(N'absp_DropTmpLookupTables') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_DropTmpLookupTables
end
go
create procedure absp_DropTmpLookupTables  

as
/*
 ##BD_BEGIN
 <font size ="3">
 <pre style="font-family: Lucida Console;" >
 ====================================================================================================
 DB Version:    MSSQL
 Purpose:       This procedure drops all the temporary lookup tables created during lookups clone.
 
 Returns:       Nothing.
 
 ====================================================================================================
 </pre>
 </font>
 ##BD_END
 

 */

begin
    set nocount on
 
    declare @tmpTbl varchar(130)
    declare @lkupTbl varchar(130)
    declare @sSql varchar(8000)
    declare @me varchar (50)
    declare @msg varchar (256)
    declare @debug int
    
    set @debug = 0
    set @me = 'absp_DropTmpLookupTables'

    set @msg = @me + ' Starting'
    
    if (@debug = 1)
    	execute absp_Util_Log_Info  @msg, @me
    
    
    declare curs  cursor fast_forward  for  select TABLENAME  from DICTLOOK 
    open curs 
    fetch next from curs  into  @lkupTbl 
    while @@fetch_status = 0
    begin 
     	set @tmpTbl ='TMP_' + dbo.trim( @lkupTbl)+'_'+dbo.trim(cast (@@SPID as varchar))
     	set @sSql ='if exists (select * from SYS.TABLES where NAME= ''' + @tmpTbl + ''') drop table ' +  @tmpTbl 
     	execute (@sSql)
     	
     	set @tmpTbl =dbo.trim(@lkupTbl) + '_COPY'+'_'+dbo.trim(cast (@@SPID as varchar))
     	set @sSql ='if exists (select * from SYS.TABLES where NAME= ''' + @tmpTbl + ''') drop table ' +  @tmpTbl 
     	execute (@sSql)
    	fetch next from curs  into  @lkupTbl 
    end
    
    close curs
    deallocate curs
    
    set @msg = @me + ' Complete'
    if (@debug = 1)
	execute absp_Util_Log_Info  @msg, @me
    
end 
    
 