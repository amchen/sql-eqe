if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_GenInListString') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GenInListString
end

go

create procedure absp_Util_GenInListString @ret_ListString varchar(max) output, @sql varchar(max), @listType char(1) = 'N' 
as
/*
##BD_BEGIN
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure returns all rows of output of a select query (in an OUTPUT parameter), consisting single 
column only, all concatenated in a single string separated by comma. All individual values are enclosed 
within single quotes if listType parameter is other than 'N' (for character data) 

Returns: Nothing

====================================================================================================

</pre>
</font>
##BD_END

##PD  @ret_ListString     ^^ This is an OUTPUT parameter where the status is returned (0 on success, non-zero on failure).
##PD  @sql        ^^ The sql query that is to be executed
##PD  @listType   ^^ Signifies if the output column is numeric or string
*/

begin

   set nocount on
   
   declare @value char(256)
   declare @delim char(1)
   declare @comma char(3)
   declare @inList varchar(MAX)
   if @listType = 'N'
   begin
      set @delim = ''
   end
   else
   begin
      set @delim = ''''
   end
   set @inList = ''
   set @comma = ''
   execute('declare genInListCurs1 cursor global for '+@sql)
   open genInListCurs1 
   
   begin try
	 fetch next from genInListCurs1 into @value
   end try

   begin catch 	
     close genInListCurs1
	 deallocate genInListCurs1
	 set @ret_ListString = ''
	 return 0
   end catch
   
   while @@fetch_status = 0
   begin
      set @inList = rtrim(ltrim(@inList))+@comma+rtrim(ltrim(@delim))+rtrim(ltrim(@value))+@delim
      set @comma = ' , '
      fetch next from genInListCurs1 into @value
   end
   close genInListCurs1
   deallocate genInListCurs1
   set @ret_ListString = @inList
end
