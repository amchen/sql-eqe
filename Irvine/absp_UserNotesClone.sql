
if exists(select * from SYSOBJECTS where ID = object_id(N'absp_UserNotesClone') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_UserNotesClone
end
 go
create procedure absp_UserNotesClone @noteType integer, @currentKey integer,@newKey integer, @targetDB varchar(130)=''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

     This procedure creates a clone of a user notes record for a given node.
    	    
Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  noteType ^^  The type of node for which the user notes is to be cloned. 
##PD  currentKey ^^  The key of the node for which the note is to be cloned.
##PD  newKey ^^  The new note key for the clone record.

*/
as
begin 


   set nocount on
   declare @sql varchar(8000)
   
   if @targetDB=''
   	set @targetDB = DB_NAME()
   	
   --Enclose within square brackets--
   execute absp_getDBName @targetDB out, @targetDB

-- this procedure will clone a Note
   set @sql = 'begin transaction; insert into  ' + dbo.trim(@targetDB) + '..USRNOTES  ( NOTE_KEY,  NOTE_TYPE, NOTES)
          			select   ' + cast(@newKey as varchar) + ', NOTE_TYPE, NOTES  from  USRNOTES UN
         				where  UN.NOTE_KEY =  ' + cast(@currentKey as varchar) + '  AND  UN.NOTE_TYPE =  ' + cast(@noteType as varchar)+'; commit transaction; '
print @sql
   execute(@sql)
end

