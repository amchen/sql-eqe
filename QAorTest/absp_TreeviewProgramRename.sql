if exists(select * from sysobjects where id = object_id(N'absp_TreeviewProgramRename') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewProgramRename
end

go
create procedure absp_TreeviewProgramRename @progKey int ,@newName char(120) 
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    SQL2005
Purpose:       This procedure renames a program to given newName for given progKey passed as parameters.

Returns:     It returns nothing. It just uses the UPDATE statement to rename a program.      

====================================================================================================
</pre>
</font>
##BD_END

##PD  @progKey ^^  The key for the program that is to be renamed.
##PD  @newName ^^  The new name of the program
*/

as
begin
   update PROGINFO set LONGNAME = @newName where PROG_KEY = @progKey
end



