if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_Replace_Slash') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_Replace_Slash
end
go

create procedure
absp_Util_Replace_Slash @ret_String varchar(MAX) output, @inputString varchar(MAX)
as
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    ASA
Purpose:

    This Procedure will replace all "\" with "/"  and "\n" with "/n" in a given string and return the modified string
    in an output parameter.

Returns:      Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  ret_String ^^  Holds the modified string.
##PD  inputString ^^  The string which is to be modified.


*/

begin

   set nocount on
   
   declare @outString varchar(MAX)
   set @outString = replace(@inputString,'\','/')
   set @outString = replace(@outString,'\n','/n')
   set @ret_String = @outString
end


