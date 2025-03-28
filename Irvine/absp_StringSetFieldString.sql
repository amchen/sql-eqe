if exists(select * from SYSOBJECTS where ID = object_id(N'absp_StringSetFieldString') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_StringSetFieldString
end
go

create procedure absp_StringSetFieldString @ret_String varchar(max) output, @inputString varchar(max), @fieldName char(120), @fieldValue char(254)
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will replace the first occurrence of the given fieldName in the input string with the fieldValue 
and give the resultant string in an out parameter.


Returns: Nothing
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @ret_String  ^^ An OUTPUT parameter where the generated string value for a given string value is returned as OUTPUT param.
##PD  @inputString ^^ Any string value
##PD  @fieldName   ^^ The substring which is to be replaced.
##PD  @fieldValue  ^^ The string to be replaced with.
*/
as
begin
 
   set nocount on
   
   declare @replNames varchar(max)
   declare @i int

   set @replNames = ''
   set @i = charindex(ltrim(rtrim(@fieldName)),@inputString)
   if @i > 0
   begin
      set @replNames = left(@inputString,@i -1)+''''+ltrim(rtrim(@fieldValue))+''''+substring(@inputString,@i+len(@fieldName),len(@inputString) -@i+len(@fieldName))
   end
   else
   begin
      set @replNames = @inputString
   end
   set @ret_String = @replNames
end



