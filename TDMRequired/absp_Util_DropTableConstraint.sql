if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_DropTableConstraint') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Util_DropTableConstraint
end
go

create procedure absp_Util_DropTableConstraint
    @baseTableName varchar(120) ,
    @cnstType      varchar(2) = 'FK'

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure drops a foreign key constraint on the baseTableName,
and optionally on the refTableName.

Returns:	nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @baseTableName ^^  The table name for which the constraints are to be dropped.
##PD  @cnstType      ^^  The type of constraint to create, FK (foreign key) is the default.

*/

as
begin

   set nocount on

  /*
  This procedure will drop a foreign key constraint on the baseTableName, and optionally on the refTableName.
  The procedure uses the table field definitions in DICTCNST.
  */

   declare @me varchar(1000)
   declare @sql varchar(1000)
   declare @refTableName varchar(120)
   declare @msgTxt01 varchar(255)
   declare @curs1_CN varchar(120)
   declare @curs1_CT varchar(2)
   declare @curs1_TN varchar(120)
   declare @curs1_FN varchar(120)
   declare @curs1_RT varchar(120)
   declare @curs1_RF varchar(120)
   declare @curs1_ACTION varchar(80)

   declare curs1 cursor dynamic local for
        select rtrim(ltrim(CNSTNAME)) as CN,rtrim(ltrim(CNSTTYPE)) as CT,rtrim(ltrim(TABLENAME)) as TN,rtrim(ltrim(FIELDNAME)) as FN,
               rtrim(ltrim(RTABLENAME)) as RT,rtrim(ltrim(RFIELDNAME)) as RF,rtrim(ltrim(MSSQL)) as ACTION
          from DICTCNST
         where TABLENAME = @baseTableName and CnstType = @cnstType

   declare @curs2_CN varchar(120)
   declare @curs2_CT varchar(2)
   declare @curs2_TN varchar(120)
   declare @curs2_FN varchar(120)
   declare @curs2_RT varchar(120)
   declare @curs2_RF varchar(120)
   declare @curs2_ACTION varchar(80)

   declare curs2 cursor dynamic local for
        select rtrim(ltrim(CNSTNAME)) as CN,rtrim(ltrim(CNSTTYPE)) as CT,rtrim(ltrim(TABLENAME)) as TN,rtrim(ltrim(FIELDNAME)) as FN,
               rtrim(ltrim(RTABLENAME)) as RT,rtrim(ltrim(RFIELDNAME)) as RF,rtrim(ltrim(MSSQL)) as ACTION
          from DICTCNST
         where RTABLENAME = @refTableName and CnstType = @cnstType

   -- set variables
   set @me = 'absp_Util_DropTableConstraint: '
   set @msgTxt01 = @me+'Begin'
   execute absp_MessageEx @msgTxt01
   set @baseTableName = rtrim(ltrim(@baseTableName))
   set @refTableName = @baseTableName

   if len(@baseTableName) > 0
   begin
	-- raiseerror if @baseTableName does not exist in DICTTBL
	if not exists(select  1 from DICTTBL where TABLENAME = @baseTableName)
	begin
		set @sql = 'Base Table '+@baseTableName+' not found in DICTTBL'
		execute absp_MessageEx @sql
		execute absp_Migr_RaiseError 1,@sql
		return
	end

	-- raiseerror if @baseTableName does not exist in DICTCOL
    if not exists(select  1 from DICTCOL where TABLENAME = @baseTableName)
    begin
		set @sql = 'Base Table '+@baseTableName+' not found in DICTCOL'
		execute absp_MessageEx @sql
		execute absp_Migr_RaiseError 1,@sql
		return
	end

	-- raiseerror if @baseTableName does not exist in DICTCNST
	if not exists(select  1 from DICTCNST where TABLENAME = @baseTableName)
	begin
		 set @sql = 'Base Table '+@baseTableName+' not found in DICTCNST'
		 execute absp_MessageEx @sql
	end
	else
	begin
		 -- for @baseTableName, get its constraints
		 open curs1
		 fetch next from curs1 into @curs1_CN,@curs1_CT,@curs1_TN,@curs1_FN,@curs1_RT,@curs1_RF,@curs1_ACTION
		 while @@fetch_status = 0
		 begin
			if exists(select 1 from sysobjects where name = @curs1_CN)
			begin
			   set @sql = 'alter table '+@curs1_TN+' drop constraint '+@curs1_CN+';'
			   execute absp_MessageEx @sql
			   execute(@sql)
			end
			else
			begin
			   set @sql = 'Constraint '+@curs1_CN+' does not exist on '+@curs1_TN+' table, '+@curs1_RT+' reference table'
			   execute absp_MessageEx @sql
			end
			fetch next from curs1 into @curs1_CN,@curs1_CT,@curs1_TN,@curs1_FN,@curs1_RT,@curs1_RF,@curs1_ACTION
		 end
		 close curs1
		 deallocate curs1
     	 end
      end

   -- raiseerror if @refTableName does not exist in DICTCNST
   if len(@refTableName) > 0
   begin
      -- raiseerror if @baseTableName does not exist in DICTTBL
      if not exists(select  1 from DICTTBL where TABLENAME = @refTableName)
      begin
		 set @sql = 'Reference Table '+@refTableName+' not found in DICTTBL'
		 execute absp_MessageEx @sql
		 execute absp_Migr_RaiseError 1,@sql
		 return
      end

      -- raiseerror if @baseTableName does not exist in DICTCOL
      if not exists(select  1 from DICTCOL where TABLENAME = @refTableName)
      begin
		 set @sql = 'Reference Table '+@refTableName+' not found in DICTCOL'
		 execute absp_MessageEx @sql
		 execute absp_Migr_RaiseError 1,@sql
		 return
      end
      if not exists(select  1 from DICTCNST where RTABLENAME = @refTableName)
      begin
		 set @sql = 'Reference Table '+@refTableName+' not found in DICTCNST'
		 execute absp_MessageEx @sql
      end
      else
      begin
		 open curs2
		 fetch next from curs2 into @curs2_CN,@curs2_CT,@curs2_TN,@curs2_FN,@curs2_RT,@curs2_RF,@curs2_ACTION
		 while @@fetch_status = 0
		 begin
			if exists(select 1 from sysobjects where NAME = @curs2_CN)
			begin
				   set @sql = 'alter table '+@curs2_TN+' drop constraint '+@curs2_CN+';'
				   execute absp_MessageEx @sql
				   execute(@sql)
			end
			else
			begin
				   set @sql = 'Constraint '+@curs2_CN+' does not exist on '+@curs2_TN+' table, '+@curs2_RT+' reference table'
				   execute absp_MessageEx @sql
			end
			fetch next from curs2 into @curs2_CN,@curs2_CT,@curs2_TN,@curs2_FN,@curs2_RT,@curs2_RF,@curs2_ACTION
		 end
		 close curs2
		 deallocate curs2
      end
   end
   set @msgTxt01 = @me+'End'
   execute absp_MessageEx @msgTxt01
end
