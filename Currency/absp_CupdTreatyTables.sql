if exists(select * from SYSOBJECTS where ID = object_id(N'absp_CupdTreatyTables') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_CupdTreatyTables
end
 go

create procedure absp_CupdTreatyTables @keyFieldName char(10),@keyFieldVal int,@cupdKey int,@debugFlag int = 0 

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure performs a currency conversion for the currency values in any of the following treaty tables
based on the keyFieldName:-
1) Retro treaty tables - RTROINFO, RTROLAYR, RTROTRIG
2) Case treaty tables - CASEINFO, CASELAYR, CASETRIG
3) Inuring cover treaty tables - INURINFO, INURLAYR, INURTRIG

Returns:       It returns nothing.                  
====================================================================================================
</pre>
</font>
##BD_END

##PD  @keyFieldName ^^  The field name whose currency values are to be updated (Eg:CASE_KEY). 
##PD  @keyFieldVal ^^  The value of the key field whose currency values are to be updated.
##PD  @cupdKey ^^  The currency update key
##PD  @debugFlag ^^  The debug flag.

*/
as
begin

   set nocount on
   
  -- standard declares
   declare @me varchar(255)
   declare @debug int
   declare @msg varchar(255)
   declare @sql varchar(1024)
   declare @sql1 varchar(255)
   declare @sTmp varchar(255)
   declare @tableName char(50)
   
  -- initialize standard items
   set @me = 'absp_CupdTreatyTables: ' -- set to my name Procedure Name
   set @debug = @debugFlag -- initialize
   set @msg = @me+'starting'
   set @sql = ''
   set @tableName = ''
   
   if(@debug > 0)
   begin
	  execute absp_messageEx @msg
   end
  -- loop through  all the treaty tables and update the currency fields
   if(@debug > 0)
   begin
	  execute absp_CupdLogMessage @cupdKey,'M','Loop through  all the treaty tables '
   end
   set @sql1 = 'select distinct rtrim(ltrim(dc.TABLENAME)) as TBL from DICTCOL as dc where dc.tablename in ( select distinct dc2.TABLENAME from DICTCOL as dc2 where dc2.fieldname = ''' + ltrim(rtrim(@keyFieldName)) + ''' and right(rtrim(ltrim(dc.fieldname)),3) = ''_CC'')'

   begin
	  declare @realField1 char(10)
	  declare @cc_field char(10)
	  declare @isDeductible char(1)
	  set @sql = 'declare eachField cursor fast_forward global for '+@sql1
	  execute(@sql)

	  open eachField 
	  fetch next from eachField into @tableName
	  while @@fetch_status = 0
	  begin
	  -- dynamically construct queries on the fly
		 declare curs_currflds  cursor fast_forward for select  REAL_FIELD,FLDNAME_CC ,IS_DEDUCT from
		 CURRFLDS where TABLENAME = @tableName

		 open curs_currflds
		 fetch next from curs_currflds into @realField1,@cc_field,@isDeductible

		 while @@fetch_status = 0
		 begin
			set @sTmp = 'left('+@cc_field+', len('+@cc_field+') - 2)'
			set @sql = 'update '+ltrim(rtrim(@tableName))+' set '
			set @sql = @sql+@realField1+' = '
			set @sql = @sql+@realField1+'* RATIO '
			set @sql = @sql+' from #CURRATIO_TMP as C where '+rtrim(ltrim(@sTmp))+' = '
			set @sql = @sql+'rtrim(ltrim(C.CODE))'
			set @sql = @sql+' and '+@keyFieldName+' = '+rtrim(ltrim(str(@keyFieldVal)))
			set @sql = @sql+' and len(dbo.trim('+ @cc_field + '))>0'
			if(@debug > 0)
				begin
					   execute absp_messageEx @sql
					   execute absp_CupdLogMessage @cupdKey,'M',@sql
				end
			execute(@sql)
			fetch next from curs_currflds into @realField1,@cc_field,@isDeductible
		 end
		 fetch next from eachField into @tableName
		 close curs_currflds
		 deallocate curs_currflds
	  end
	  close eachField
	  deallocate eachField
   end
  -------------- end --------------------
   if(@debug > 0)
   begin
	  set @msg = @me+'complete'
	  execute absp_messageEx @msg
	  execute absp_CupdLogMessage @cupdKey,'M',@msg
   end
end