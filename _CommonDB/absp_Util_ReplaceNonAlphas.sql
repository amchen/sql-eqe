if exists(select * from sysobjects where ID = object_id(N'absp_Util_ReplaceNonAlphas') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_ReplaceNonAlphas
end
 go
create procedure --=================================================
absp_Util_ReplaceNonAlphas @ret_newString varchar(max) output ,@origString varchar(2000),@debug int = 0,@allowed varchar(255) = '' 
/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will replace all non-alphanumeric characters (excluding a-z,0-9 and _) with an underscore (_)
character in a given string and return the modified string in an OUTPUT parameter.
If the optional allowed string is given, the returned string will contain non-alphanumeric characters 
specified in the allowed string.

Returns:       Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @ret_newString ^^  This is an OUTPUT parameter which holds the modified string.
##PD  @inputString ^^  The string which is to be modified.
##PD  @debug ^^  The debug Flag
##PD  @allowed ^^  A list of characters which are to be kept unchanged in the given string.



*/
as
begin
 
   set nocount on
   
 /*
  returns a replacement string from an original string.   The new string
  will have all non-alphanumeric characters replaced with an underscore (_) character.

  If the optionl "allowed" string is given, any character in the string is
  returned in the replacement string even if it is not alphanumeric.
  */
  
   declare @length int
   declare @length1 int
   declare @position int
   declare @position1 int
   declare @ch char(2)
   declare @ch1 char(2)
   declare @allow int
   set @ret_newString = ''
   set @length = len(@origString)
   set @length1 = len(@allowed)
   set @position = 1
   while @position <= @length
   begin
      set @ch = substring(@origString,@position,1)
      set @position1 = 1
      set @allow = 0
      while @position1 <= @length1
      begin
         set @ch1 = substring(@allowed,@position1,1)
         if @ch = @ch1
         begin
            set @allow = 1
         end
         set @position1 = @position1+1
      end
      if @debug > 1
      begin
         print 'absp_Util_ReplaceNonAlphas: @ch = '+@ch
      end
      if(@allow = 1) or(@ch >= 'A' and @ch <= 'Z') or(@ch >= 'a' and @ch <= 'z') or(@ch >= '0' and @ch <= '9') or(@ch = '_')
      begin
         set @ret_newString = @ret_newString+ltrim(rtrim(@ch))
      end
      else
      begin
         set @ret_newString = @ret_newString+'_'
      end
      set @position = @position+1
      if @debug > 1
      begin
         print 'absp_Util_ReplaceNonAlphas: ret_newString = '+@ret_newString
      end
   end
   if @debug > 0
   begin
      print 'absp_Util_ReplaceNonAlphas: \x0AorigString = '''+@origString+'\x0A'+'''ret_newString = '''+@ret_newString+''''
   end

end



