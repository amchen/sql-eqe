if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Migr_MakeCopyTable') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Migr_MakeCopyTable
end
 go

create procedure absp_Migr_MakeCopyTable @thePrefix char(10) = '',
										 @thePostfix char(10) = '_MIGRTMP',
										 @dbSpaceName char(40) = '',
										 @theTableName char(120),
										 @dropFirstFlag integer = 0,
										 @destDbName varchar(120) = ''

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates a indexed table with the same structure as the given base table 
and also populates it with the data same as that of the base table.


Returns:       Nothing.

=================================================================================
</pre>
</font>
##BD_END

##PD  @thePrefix     ^^ An string value for the prefix.
##PD  @thePostfix    ^^ An string value for the postfix.
##PD  @dbSpaceName   ^^ The name of the DB space.
##PD  @theTableName  ^^ A string containing the base table name.
##PD  dropFirstFlag  ^^ A flag to check if the table already exists and needs to be dropped first
*/
as

begin

   set nocount on
   
  -- This will make a copy of a table from SYSTABLE
   declare @tmpTblNm char(120)
   declare @debugFlag int
   declare @me varchar(255)
   declare @sql varchar(max)
   declare @HasIdentity int
   declare @msgTxt1 varchar(255)
   declare @ret_fieldNames varchar(max)
   declare @srcDbName varchar(120)

   set @srcDbName = DB_NAME()
   if @destDbName = '' set @destDbName = DB_NAME()
  
  -- change @debugFlag to a higher number for more debug trace
   set @debugFlag = 1
   set @me = 'absp_Migr_MakeCopyTable: '
   set @msgTxt1 = @me+'Begin'
   execute absp_MessageEx @msgTxt1
   if @debugFlag > 0
   begin
	  set @msgTxt1 = @me+'theTableName = '+@theTableName
	  execute absp_MessageEx @msgTxt1
   end

   set @tmpTblNm = rtrim(ltrim(@thePrefix))+rtrim(ltrim(@theTableName))+rtrim(ltrim(@thePostfix))
   
    --Defect  SDG__00023108 - Add additional parameter @dropFirstFlag--
    IF OBJECT_ID (@destDbName + '.dbo.' + @tmpTblNm,'U') IS NOT NULL
    begin
	    --Target Copy table exists--
		if @dropFirstFlag = 1 
		begin
			--Drop the table first--
			set @msgTxt1 = 'The table ' + rtrim(@tmpTblNm)  + ' already exists. Drop the table first.' 
			exec absp_MessageEx  @msgTxt1
			execute('use '  + @destDbName + ' drop table ' + @tmpTblNm)
		end
		else
		begin
			--return doint nothing--
			set @msgTxt1 = 'The table ' + rtrim(@tmpTblNm)  + ' already exists. ' 
			exec absp_MessageEx  @msgTxt1
			set @msgTxt1 =  @me+ 'End'
			exec absp_MessageEx  @msgTxt1
			return
		end 
    end 
--
    
   exec absp_Util_CreateSysTableScript @sql output, @theTableName,@tmpTblNm,@dbSpaceName,1,0,@destDbName
   if @debugFlag > 0
   begin
	  set @msgTxt1 = @me+@sql
	  execute absp_MessageEx @msgTxt1
   end
   execute(@sql)

   
   
   create Table #HAS_IDENTITY(has_identity int default 0) 	
   set @sql = ' use [' + @destDbName + '] declare @hasIdentity int ' +
    'select @hasIdentity = isnull(objectproperty ( object_id(''' + @tmpTblNm +''') , ''TableHasIdentity'' ), -1) ' +
   ' insert into ' + @destDbName + '.#HAS_IDENTITY values(@hasIdentity) '
   --print @sql	
   execute(@sql)
   select @HasIdentity = has_identity from #HAS_IDENTITY
   drop table #HAS_IDENTITY
   

   If @HasIdentity = 0   --@HasIdentity is 0 if there is no identity property
   begin
		 set @sql = 'insert into [' + @destDbName + '].dbo.' + rtrim(ltrim(@tmpTblNm)) + ' select * from ' + @theTableName;
   end
   else
   begin	 --@HasIdentity is 1 if the table has identity property
   		 exec absp_DataDictGetFields @ret_fieldNames out,@theTableName,0
		 set @sql = 'use ' + @destDbName + ' set identity_insert ' + rtrim(ltrim(@tmpTblNm)) +' on;'
		 set @sql=@sql + ' insert into ' + rtrim(ltrim(@tmpTblNm)) + '('+ @ret_fieldNames + ')' 
		 set @sql=@sql + ' select * from ' +  '[' + @srcDbName + '].dbo.' + rtrim(ltrim(@theTableName)) + '; set identity_insert ' + rtrim(ltrim(@tmpTblNm)) +' off'
   end
   if @debugFlag > 0
   begin
		  set @msgTxt1 = @me+@sql
		  execute absp_MessageEx @msgTxt1
   end
   execute(@sql)
   set @msgTxt1 = @me+'End'
   execute absp_MessageEx @msgTxt1
end