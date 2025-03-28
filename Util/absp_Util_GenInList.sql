if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_GenInList') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_GenInList
end
go

create procedure absp_Util_GenInList (@ret_OutputList varchar(max) output, @sql varchar(max) ,@listType char(1) = 'N' ,@debug int = 0 )

as
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:	MSSQL
Purpose:	This function returns all rows of output of a select query, consisting single 
column only, all concatenated in a single string separated by comma and enclosed with
the "IN" clause All individual values are enclosed within single quotes if listType
parameter is other than 'N' (for character data) This string returned by this 
function basically forms the "In list " for a top level query.

Returns:        It returns all rows of output of a query concatenated in a single string separated by
comma and placed within " IN () " clause. It returns " in ( -2147000000 ) " if the query
provided raises an error or returns in ( ''^^^'' ) if the query provided returns an 
empty result set.
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @sql 	 ^^  Single column select query.
##PD  @ret_OutputList    ^^  It is an OUTPUT param where all rows of the output of a query are concatenated in a single string separated by comma and placed within " IN () " clause  
##PD  @listType  ^^  Default is 'N' for numeric list else other than 'N' (enclosed within single quotes)
##PD  @debug     ^^  The debug flag

*/
 /*
This function will return a string like in( 123, 456, 789 ) or in( 'aaa', 'bbb', 'ccc' ).
The arguments specify the SQL query to execute to develop the list, and whether the list contains strings or numbers

usage:  
set @myList = absp_Util_GenInList ( 'select value from table', 'N') for numeric values  (this is the default)
set @myList = absp_Util_GenInList ( 'select string from table', 'S') for string values
*/
begin

   set nocount on
   
   declare @inList varchar(MAX)
   set @inList = ''
   exec absp_Util_GenInListString @inList output,@sql,@listType

    --	normal case
   if len(@inList) > 0
   begin
      set @inList = ' in ( '+ltrim(rtrim(@inList))+' ) '
   end
   else
   begin
    --	prevent the case of empty @inList return, the caller will throw an exception
    --  because of syntax error: 'in(' is returned in this case 
    --  hope the in-list will not hit these imaginary strings below
      if @listType = 'N'
      begin
         set @inList = ' in ( -2147000000 ) '
      end
      else
      begin
         set @inList = ' in ( ''^^^'' ) '
      end
   end

   if @debug > 0 
   begin
      print '@inList = '+@inList 
   end 
   set @ret_OutputList = @inList
end





