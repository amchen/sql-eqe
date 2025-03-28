
if exists(select * from SYSOBJECTS where ID = object_id(N'absp_UserNotesPurge') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_UserNotesPurge
end
 go

create procedure 
absp_UserNotesPurge @noteType int ,@currentKey int 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure deletes the user notes for a given node key and type.


Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  @noteType ^^  The type of node for which the user note is to be deleted. 
##PD  @currentKey ^^  The key of the node for which the user note is to be deleted. 

*/
as
begin

   set nocount on
   
  -- this procedure will purge a Note
   delete from USRNOTES where
   NOTE_KEY = @currentKey and NOTE_TYPE = @noteType
end




