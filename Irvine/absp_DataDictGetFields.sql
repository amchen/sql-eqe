if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_DataDictGetFields') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_DataDictGetFields
end
go
create procedure dbo.absp_DataDictGetFields
												  @ret_fieldNames varchar(max) output,
												  @myTableName varchar(1000),
												  @skipKeyFieldNum int,
												  @correlation varchar(10) = ''

/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL
Purpose:		This procedure will return the column names of a given table name, 
				as comma separated values.
Returns: 		Nothing.
====================================================================================================
</pre>
</font>
##BD_END 
##PD  @ret_fieldNames ^^ A generated list comprising of the column names of a given table is an OUTPUT parameter.
##PD  @myTableName ^^ A string containing the name of the table.
##PD  @skipKeyFieldNum ^^ The integer value of the column which is to be skipped from the list.
##PD  @correlation ^^ A string that is appended in front of each column name in the list of column names that is returned.
*/
as

begin
  /*
  skipKeyFieldNum is 0 to not skip any fields, or it is the number of a field that will not
  be included in the list of field names returned.   SkipKeyFieldNum is typlically 1 to skip the first field.
  Note:  correlation is optional.   It must be in the form "mt.", including the dot.
  The correlation will be added in front of each field name.    It is used when other
  tables in a where clause refer to the same fieldname(s) as generated in the main table list
  this function returns.
  */
	set nocount on
	declare @sSql varchar(max)
	declare @fldName varchar(100)
	set @fldName=''
	set @ret_fieldNames = ' '
	set @sSql='select  ''' + @correlation +'''+ FIELDNAME from DICTCOL where  TABLENAME = '''+ rtrim(ltrim(@myTableName))+''' and FIELDNUM<>' + str(@skipKeyFieldNum) + ' order by FIELDNUM asc'
	execute('declare curs_fldName cursor global Fast_Forward for '+@sSql)

    open curs_fldName 

    fetch next from curs_fldName into @fldName

	while @@fetch_status = 0

	begin       
		set @ret_fieldNames= @ret_fieldNames+', ' + ltrim(rtrim(@fldName))        
		fetch next from curs_fldName into @fldName
	end

	close curs_fldName
	deallocate curs_fldName  

	if len(@ret_fieldNames)>3       
		set @ret_fieldNames=substring(@ret_fieldNames,4,len(@ret_fieldNames)-3) 
end
