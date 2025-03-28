if exists(select * from SYSOBJECTS where ID = object_id(N'absp_StringSetFieldInteger') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_StringSetFieldInteger
end

go

create  procedure absp_StringSetFieldInteger @ret_replNames varchar(max) output, @inputString varchar(max), @fieldName char(120), @fieldValue int
/* 
##BD_BEGIN
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
=================================================================================
DB Version:    MSSQL
Purpose: This procedure will replace the first occurrence of the given fieldName in the input string with the fieldValue 
and returns the resultant string in an OUTPUT parameter.


Returns: Nothing   
=================================================================================
</pre> 
</font> 
##BD_END 

##PD  @ret_replNames ^^  (OUT Param)The resultant string after replacing the given fieldName with the given fieldValue.   
##PD  @inputString ^^ Any string value.
##PD  @fieldName  ^^ The substring which is to be replaced.
##PD  @fieldValue ^^ The string to be replaced with.

*/
as
begin
   
 
   set nocount on
   
  declare @i int
   set @i = charindex(ltrim(rtrim(@fieldName)),@inputString)
   if @i > 0
   begin
      set @ret_replNames = left(@inputString,@i -1)+rtrim(ltrim(cast(@fieldValue as char)))+substring(@inputString,@i+len(ltrim(rtrim(@fieldName))),len(@inputString) -@i+len(ltrim(rtrim(@fieldName))))
   end
   else
   begin
      set @ret_replNames = @inputString
   end
   
end




