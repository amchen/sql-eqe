if exists(select * from SYSOBJECTS where ID = object_id(N'absp_GenericTableCloneSeparator') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_GenericTableCloneSeparator
end

go

create  procedure absp_GenericTableCloneSeparator @ret_separator char(2) output 
/*
##BD_BEGIN
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns a tab and a space. This forms the separator needed by 
all the "trio" functions which calls this procedure

Returns:
a horizontal tab and a space (CHAR(09) + ' ')	

====================================================================================================

</pre>
</font>
##BD_END
##PD @ret_separator ^^ a tab and a space (tab seperator)

*/
as
begin
 
   set nocount on
   
 -- this is the separator needed by all the "trio" functions
   set @ret_separator = char(9)+' '
end




