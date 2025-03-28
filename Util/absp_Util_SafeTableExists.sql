if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_SafeTableExists') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_SafeTableExists
end

go

create procedure absp_Util_SafeTableExists @tableName CHAR(120),@fieldName CHAR(120),@fieldType CHAR(1) = 'A' 
-- versis 'N'
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       This procedure returns 1 if the given table and field exists and the field type is correct 
else returns 0. 

Returns:       Returns 1 if the given table and field exists and the field type is correct else 0
====================================================================================================
</pre>
</font>
##BD_END

##PD  tableName ^^ The SQL statement that is to be tested.
##PD  fieldName ^^ A flag which indicates if a message is to be recorded in the log.
##PD  fieldType ^^ The field type (A for alphanumeric, N for integer)

*/

    --message @tableName + ' not found';
    --return 0;
as
begin

   set nocount on
   
  /*
  usage:   @result = call absp_Util_SafeTableExists('TheTableName' , 'AFieldName', 'N')
  usage:   @result = call absp_Util_SafeTableExists('TheTableName' , 'AFieldName', 'A')


  This procedure is to be used to test if a local temporary table exists.

  For Alpha fields,
  It will test if a given table name has a given field name by updating the field from 'xyzzy' to 'xyzzy'.

  For Numeric fields,
  It will test if a given table name has a given field name by updating the field from -99999 to -99999.

  It will catch any exception the update causes.

  The procedure returns 1 if the table and field exist
  otherwise it returns 0.
  */
	declare @retVal INT
	declare @IdentityStat INT
	Declare @sql varchar(max)
--	IF Exists (Select 1 From SysObjects  Where Name = + '' + Ltrim(Rtrim(@tableName))  + ''  ) And Exists (Select 1 From SysColumns  Where Name = + '' + Ltrim(Rtrim(@fieldName))  + '')
--				Set @retVal = 1 	
--			Else  		
--				IF exists (Select 1 From Tempdb.Information_Schema.Columns 
--									Where Table_Name Like  + '' + Ltrim(Rtrim(@tableName))  + '%' 
--									And Column_Name =  + '' + @fieldName + '')
--					Set @retVal = 1  
--				Else 
--					Set @retVal = 0 
--		end
--
--	Return @retVal


--Select @tableName, @fieldName, @fieldType
Begin Try
	if @fieldType = 'A' 
		Begin
			--set @sql = 'update ' + Ltrim(Rtrim(@tableName)) +  ' set ' + Ltrim(Rtrim(@fieldName)) + ' = ''xyzzy'' where ' + Ltrim(Rtrim(@fieldName)) + ' = ' + '''' + 'xyzzy' + '''';
		set @sql = 'delete from ' + Ltrim(Rtrim(@tableName)) + ' where ' + Ltrim(Rtrim(@fieldName)) + ' = ' + '''' + 'xyzzy' + '''';
		End
	else
		Begin			
			--set @sql = 'update ' + Ltrim(Rtrim(@tableName)) + ' set ' + Ltrim(Rtrim(@fieldName)) + ' = -999999 where ' + Ltrim(Rtrim(@fieldName)) + ' = -999999';
		set @sql = 'delete from ' + Ltrim(Rtrim(@tableName)) + ' where ' + Ltrim(Rtrim(@fieldName)) + ' = -999999';
		End

	Execute (@sql)

	Set @retVal = 1

	Return @retVal
End try

Begin Catch
	Set @retVal = 0

	Return @retVal
End Catch

End





