if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Util_CreateTableConstraint') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_Util_CreateTableConstraint
end
go

create procedure absp_Util_CreateTableConstraint
    @baseTableName varchar(120) ,
    @cnstType      varchar(2) = 'FK'

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure creates a foreign key constraint on the baseTableName,
and optionally on the refTableName.

Returns:	nothing.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @baseTableName ^^  The table name for which the constraints are to be created.
##PD  @cnstType      ^^  The type of constraint to create, FK (foreign key) is the default.

*/

as
begin

   set nocount on

  /*
  This procedure will create all foreign key constraints on the baseTableName.
  The procedure uses the table field definitions in DICTCNST.
  */

   declare @me varchar(1000)
   declare @sql varchar(1000)
   declare @refTableName varchar(120)
   declare @msgTxt01 varchar(255)
   declare @CN1 varchar(120)
   declare @CT1 varchar(2)
   declare @TN1 varchar(120)
   declare @FN1 varchar(120)
   declare @RT1 varchar(120)
   declare @RF1 varchar(120)
   declare @ACTION1 varchar(80)

   declare curs1 cursor dynamic local for
        select rtrim(ltrim(CNSTNAME)) as CN,rtrim(ltrim(CNSTTYPE)) as CT,rtrim(ltrim(TABLENAME)) as TN,rtrim(ltrim(FIELDNAME)) as FN,
               rtrim(ltrim(RTABLENAME)) as RT,rtrim(ltrim(RFIELDNAME)) as RF,rtrim(ltrim(MSSQL)) as ACTION
          from DICTCNST
        where TABLENAME = @baseTableName and CnstType = @cnstType

   declare @CN2 varchar(120)
   declare @CT2 varchar(2)
   declare @TN2 varchar(120)
   declare @FN2 varchar(120)
   declare @RT2 varchar(120)
   declare @RF2 varchar(120)
   declare @ACTION2 varchar(80)
   declare @columnlist        varchar(8000)

   -- set variables
   set @me = 'absp_Util_CreateTableConstraint: '
   set @msgTxt01 = @me+'Begin'
   execute absp_MessageEx @msgTxt01
   set @baseTableName = rtrim(ltrim(@baseTableName))
   set @refTableName = @baseTableName

   declare curs2 cursor dynamic local for
        select rtrim(ltrim(CNSTNAME)) as CN,rtrim(ltrim(CNSTTYPE)) as CT,rtrim(ltrim(TABLENAME)) as TN,rtrim(ltrim(@columnlist)) as FN,
               rtrim(ltrim(RTABLENAME)) as RT,rtrim(ltrim(@columnlist)) as RF,rtrim(ltrim(MSSQL)) as ACTION
          from DICTCNST
         where RTABLENAME = @refTableName and CnstType = @cnstType

   if len(@baseTableName) > 0
   begin
	-- raiseerror if @baseTableName does not exist in DICTTBL
	if not exists(select  1 from DICTTBL where TABLENAME = ltrim(rtrim(@baseTableName)))
	begin
		 set @sql = 'Base Table '+ltrim(rtrim(@baseTableName))+' not found in DICTTBL'
		 --execute absp_MessageEx @sql
		 --execute absp_Migr_RaiseError 1,@sql
		 return
	end

	-- raiseerror if @baseTableName does not exist in DICTCOL
	if not exists(select  1 from DICTCOL where TABLENAME = @baseTableName)
	begin
		set @sql = 'Base Table '+ltrim(rtrim(@baseTableName))+' not found in DICTCOL'
		--execute absp_MessageEx @sql
		--execute absp_Migr_RaiseError 1,@sql
		return
	end

	-- check if @baseTableName exists in DICTCNST
	if not exists(select  1 from DICTCNST where TABLENAME = @baseTableName)
	begin
		set @sql = 'Base Table '+ltrim(rtrim(@baseTableName))+' not found in DICTCNST'
		--execute absp_MessageEx @sql
	end
	else
	begin
		 -- for @baseTableName, get its constraints
		 open curs1
		 fetch next from curs1 into @CN1,@CT1,@TN1,@FN1,@RT1,@RF1,@ACTION1
		 while @@fetch_status = 0
		 begin
		 --	select  * from sys.foreign_keys where name = @CN1
			if not exists(select 1 from sysobjects where name = @CN1)
			begin

				set @columnlist = NULL;
				select @columnlist = COALESCE(@columnlist + ',', '') + '[' + t.RFieldName + ']'
					from DictCnst t
					where TableName = @baseTableName
					and CNSTNAME= @CN1
					order by FieldOrder

			   set @sql = 'alter table '+ltrim(rtrim(@TN1))+' add constraint '+ltrim(rtrim(@CN1))+' foreign key('+ltrim(rtrim(@columnlist))+') references '+ltrim(rtrim(@RT1))+' ('+ltrim(rtrim(@columnlist))+') '+ltrim(rtrim(@ACTION1))+';'
			   execute absp_MessageEx @sql
			   execute(@sql)
			end
			else
			begin
			   set @sql = 'Constraint '+@CN1+' already exists on '+@TN1+' table, '+@RT1+' reference table'
			   --execute absp_MessageEx @sql
			end
			fetch next from curs1 into @CN1,@CT1,@TN1,@FN1,@RT1,@RF1,@ACTION1
		 end
		 close curs1
		 deallocate curs1
	  end
   end

   -- raiseerror if @refTableName does not exist in DICTCNST
   if len(@refTableName) > 0
   begin
	  -- raiseerror if @refTableName does not exist in DICTTBL
	  if not exists(select  1 from DICTTBL where TABLENAME = @refTableName)
	  begin
		 set @sql = 'Reference Table '+@refTableName+' not found in DICTTBL'
		 --execute absp_MessageEx @sql
		 --execute absp_Migr_RaiseError 1,@sql
		 return
	  end

	  -- raiseerror if @refTableName does not exist in DICTCOL
	  if not exists(select  1 from DICTCOL where TABLENAME = @refTableName)
	  begin
		 set @sql = 'Reference Table '+@refTableName+' not found in DICTCOL'
		 --execute absp_MessageEx @sql
		 --execute absp_Migr_RaiseError 1,@sql
		 return
	  end

	  -- check if @refTableName exists in DICTCNST
	  if not exists(select  1 from DICTCNST where RTABLENAME = @refTableName)
	  begin
		 set @sql = 'Reference Table '+@refTableName+' not found in DICTCNST'
		 --execute absp_MessageEx @sql
	  end
	  else
	  begin
		 -- for @refTableName, get its constraints
		 open curs2
		 fetch next from curs2 into @CN2,@CT2,@TN2,@FN2,@RT2,@RF2,@ACTION2
		 while @@fetch_status = 0
		 begin
			set @columnlist = NULL;
			select @columnlist = COALESCE(@columnlist + ',', '') + '[' + t.RFieldName + ']'
			from DictCnst t
			where TableName = @TN2
			and CnstName=@CN2
			order by FieldOrder
			--print 'cur2: '+ @columnlist

			--select  * from sys.foreign_keys where name = @CN2
			if not exists(select 1 from sysobjects where name = @CN2)
			begin
			   set @sql = 'alter table '+ltrim(rtrim(@TN2))+' add constraint '+ltrim(rtrim(@CN2))+' foreign key('+ltrim(rtrim(@columnlist))+') references '+ltrim(rtrim(@RT2))+' ('+ltrim(rtrim(@columnlist))+') '+ltrim(rtrim(@ACTION2))+';'
			   --Print '@sql: '+@sql
			   execute absp_MessageEx @sql
			   execute(@sql)
			end
			else
			begin
			   set @sql = 'Constraint '+@CN2+' already exists on '+@TN2+' table, '+@RT2+' reference table'
			   --execute absp_MessageEx @sql
			end
			fetch next from curs2 into @CN2,@CT2,@TN2,@FN2,@RT2,@RF2,@ACTION2
		 end
		 close curs2
		 deallocate curs2
          end
   end
   set @msgTxt01 = @me+'End'
   execute absp_MessageEx @msgTxt01
end
