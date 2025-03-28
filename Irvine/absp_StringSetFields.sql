if exists(select * from SYSOBJECTS where ID = object_id(N'absp_StringSetFields') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_StringSetFields
end
 go

 
create procedure absp_StringSetFields @ret_replNames varchar(max) output, @inputString varchar(max), @fieldValueTrios varchar(max)
/*
##BD_BEGIN  
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    ASA
Purpose:

This procedure will replace columns with specified values in a list of comma separated column names 
and return the resultant string in an OUTPUT parameter.

Returns: Nothing.
====================================================================================================
</pre>
</font>
##BD_END 

##PD  @ret_replNames ^^ An OUTPUT parameter where the generated string value for a given string value is returned.
##PD  @inputString ^^ comma+space separated list of field names.
##PD  @fieldValueTrios  ^^ Delimited string containing three fields for each substitution request.

*/
as
begin

   set nocount on
   

 /*=================================================
  * absp_StringSetFields(inputString , fieldValueTrios)
  *
  * This function is called by absp_GenericTableCloneRecords and Archive/Restore
  *
  * It scans an inputString and replaces requested parts
  *
  * The inputString should a comma+space separated list of field names
  * formated for an INSERT.    The function absp_DataDictGetFields will return such a list.
  *
  * The fieldValueTrios are delimited string containing three fields for
  * each substitution request:
  *   [FieldType\t FieldName\t Fieldvalue]\t [FieldType\t FieldName\t Fieldvalue]\t ...
  *
  * Where \t is a separater defined by
  *
  *	DECLARE @tabSep  CHAR(2);
  *	@tabSep = CALL  absp_GenericTableCloneSeparator ( );
  *
  * FieldType is either 'STR' for a String type or 'INT' for numerics
  *      String types will have single-quotes added before and after.
  * FieldName is the Field whose value is to be substituted
  * FieldValue is the substition value for the field
  *
  *
  * Example:
  *   Substitute 54321 for BRANCH_ID and 'My branch' for U_BRN_NM
  *
  * inputString =  'BRANCH_ID, TRANS_ID, U_BRN_ID, U_BRN_NM, IN_LIST, DFLT_ROW'
  * fieldValueTrios = 'INT\t BRANCH_ID\t 54321\tSTR\t U_BRN_NM\t My Branch\t '
  *
  * The above will return
  *    54321, TRANS_ID, U_BRN_ID, 'My Branch', IN_LIST, DFLT_ROW
  *=================================================*/
  -- Type (  INT, STR )
  
  -- FieldName
  
  -- New Value for FieldName
  
   declare @fieldValTrio varchar(max)
   declare @n1 int
   declare @n2 int
   declare @n3 int
   declare @fldType char(10)
   declare @fldName char(120)
   declare @fldVal char(1024)
   declare @tabSep char(2)

   execute absp_GenericTableCloneSeparator @tabSep output

   set @fieldValTrio = @fieldValueTrios
   set @ret_replNames = @inputString
   
   set @n1 = 1 --psb fix in case you give it a bad trio to exit otherwise it went to infinite loop
   while (len(@fieldValTrio) > 0 and @n1 > 0)
   begin
      
      set @n1 = charindex(@tabSep,@fieldValTrio)
      
      if (@n1 > 0)
      begin
          
         set @n2 = charindex(@tabSep,@fieldValTrio,@n1+len(@tabSep))
         if @n2 > 0
         begin
            set @n3 = charindex(@tabSep,@fieldValTrio,@n2+len(@tabSep))
            set @fldType = rtrim(ltrim(LEFT(@fieldValTrio,@n1 -1)))
            set @fldName = rtrim(ltrim(substring(@fieldValTrio,@n1+len(@tabSep),@n2 -@n1 -len(@tabSep))))
            if @n3 > 0
            begin
               set @fldVal = rtrim(ltrim(substring(@fieldValTrio,@n2+len(@tabSep),@n3 -@n2 -len(@tabSep))))
            end
            else
            begin
               set @fldVal = rtrim(ltrim(substring(@fieldValTrio,@n2+len(@tabSep),len(@fieldValTrio) -@n2+len(@tabSep))))
            end
            if @fldType = 'STR'
            begin
               execute absp_StringSetFieldString @ret_replNames output,@ret_replNames,@fldName,@fldVal
               
            end
            else
            begin
               if @fldType = 'INT'
               begin
                  
                  execute absp_StringSetFieldInteger @ret_replNames output, @ret_replNames,@fldName,@fldVal

               end
            end
            if @n3 > 0
            begin
               set @fieldValTrio = rtrim(ltrim(substring(@fieldValTrio,@n3+2,len(@fieldValTrio) -@n3+2)))
            end
            else
            begin
               set @fieldValTrio = ''
            end
         end
      end
   end
--RETURN  @retVal;
end







