if exists(select * from SYSOBJECTS where id = object_id(N'absp_GenericTableExists') and OBJECTPROPERTY(id,N'IsProcedure') = 1)
begin
   drop procedure absp_GenericTableExists
end
 go
create  procedure absp_GenericTableExists ( @tableName char(120))

/*
##BD_BEGIN 
<font size ="3"> 
<pre style="font-family: Lucida Console;" > 
====================================================================================================
DB Version:    MSSQL
Purpose:

	This procedure checks the existence of a particular table.
        
Returns: An integer value
          = 0, the table does not exist.
          = 1, the table exists 
               
	
			
====================================================================================================

</pre>
</font>
##BD_END

##PD @tableName ^^ Table name for which number of rows are required to be found out.

##RD @ret_Status ^^ An Out parameter where the integer value 0 is returned  when the table does not exist,else 1 is given when the table exists 


*/
as
Begin

   set nocount on
   
	declare @cntRows int;
	declare @ret_Status int;

	Declare @Sql Varchar (1000)
	Begin Try
		Select @cntRows = Object_Id(@tableName)
		If @cntRows > 0 
			Begin 
				Set @ret_Status = 1;
			End
		Else
			Begin
				Set @ret_Status = 0
			End
			
		return @ret_Status;
	End Try

	Begin Catch
		Select Error_Line(), Error_Number(), Error_Message()
	End Catch
end 


