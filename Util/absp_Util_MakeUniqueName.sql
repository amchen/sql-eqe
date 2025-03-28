if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_MakeUniqueName') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_MakeUniqueName
end
go
 
create procedure absp_Util_MakeUniqueName @ret_nextName varchar ( 1200 )  output, @currentName varchar(120),@tableName varchar(400),@nameField varchar(1200),@useRandomPrefix bit = 0 

/*
##BD_BEGIN 
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure will return a unique name string for a particular field value of a table depending on passed 
values in the parameter.

Returns:       Nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @ret_nextName ^^  Returns the generated unique name string.This is an OUTPUT parameter
##PD  @currentName ^^  A name string which will be used to generate the new unique name.
##PD  @tableName ^^  The table namefor which the unique string is to be generated.
##PD  @nameField ^^  The field name for which the unique string is to be generated.
##PD  @useRandomPrefix ^^  A flag which signifies how it will generate the unique name. 

*/
as
begin

   set nocount on
   
   declare @baseName varchar(1200)
   declare @cnt1 int
   declare @n2 int
   declare @n3 int
   declare @n4 int
   declare @cpyCode varchar(80)
   declare @curNum varchar(800)
   declare @sql nvarchar(4000)
  --message 'inside  absp_Util_MakeUniqueName';
  --message 'currentName  = ' + currentName ;
  --message 'tableName  = ' + tableName ;
  --message 'nameField  = ' + nameField ;
  -- this will allow for up to 999 copies of even the longest name
   set @baseName = rtrim(ltrim(left(@currentName,110)))
   set @ret_nextName = @baseName
   set @cnt1 = 1
   set @n2 = 1
   set @cpycode = ' (copy '
  -- we see if it is already a copy n and if so just bump n
   set @n3 = charindex(@cpycode,@baseName)
  -- if n3 > 0 then  it is a copy
   if @n3 > 0 and @useRandomPrefix = 0
   begin
    -- find what n is
      set @curNum = substring(@baseName,@n3+len(@cpycode),len(@baseName) -@n3+LEN(@cpycode))
      set @n4 = charindex(')',@curNum)
    -- if we can find it, then increment it
      if @n4 > 0
      begin
         set @n2 = 1+cast(left(@curNum,@n4 -1) as int)
      -- set things up so the next part just works
         set @baseName = left(@baseName,@n3 -1)
         set @ret_nextName = @baseName+@cpycode+rtrim(ltrim(cast(@n2 as char)))+')'
      end
   end
  -- what we do is look & see if your name is unique.
  -- we add (copy n) to it until we find one that works.
  -- you could break this, but noone will in reality
   while @cnt1 > 0 and @n2 < 1000
   begin
      set @sql = 'select @cnt1 = count ( * )  FROM  '+rtrim(ltrim(@tableName))+'  where '+rtrim(ltrim(@nameField))+' =  '+''''+@ret_nextName+''''
      exec sp_executesql @sql,N'@cnt1 int output',@cnt1 output
    -- if  cnt > 0 then the name exists
      if @cnt1 > 0
      begin
         if @useRandomPrefix = 0
         begin
            set @ret_nextName = @baseName+@cpycode+rtrim(ltrim(cast(@n2 as char)))+')'
         end
         else
         begin
            set @ret_nextName = @baseName+' ('+rtrim(ltrim(str(7559*rand())))+')'
         end
         set @n2 = @n2+1
      end
   end

end



