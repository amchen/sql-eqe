if exists(select * from SYSOBJECTS where ID = object_id(N'absp_Util_GetNewId') and objectproperty(ID,N'isprocedure') = 1)
begin
	drop procedure absp_Util_GetNewId
end
go

create procedure absp_Util_GetNewId
	@aTableName varchar(120),
	@idField    varchar(120),
	@countryID  char(3) = '',
	@sysFlag    int = 0,
	@display    int = 0

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:       The function returns a newId for the given column of the table ensuring that the ID is within the
limits allowed for the column. It inserts a record in the table with the new Id.

Returns:       A newId for the specified table.
====================================================================================================
</pre>
</font>
##BD_END

##PD  @aTableName ^^ The table name for which a new ID is to be generated.
##PD  @idField ^^ The field name for which the new ID is to be generated.
##PD  @countryID ^^ The country ID.
##PD  @sysFlag ^^ A flag to indicate if the new ID should be within the system limits.
##PD  @display ^^ A flag to indicate if a message is to be displayed. (Required for debugging)

##RD @newID ^^  A newId for the specified table.
*/
as

begin

   set nocount on

   declare @newID int
   declare @idString char(10)
   declare @sql varchar(2000)
   declare @sql1 nvarchar(3000)
   declare @uidMin int
   declare @uidMax int
   declare @sysMin int
   declare @sysMax int
   declare @whereClause varchar(255)
   declare @transIdCol char(15)
   declare @transIdVal char(10)
   declare @cnt int
   declare @klist varchar(1000)
   declare @vlist varchar(1000)
   declare @fieldName varchar(100)
   declare @fieldType char(1)

   -- =================================================
   -- get a new ID
   -- Insure the ID does not fall within the reserved SYSTEM id area,
   -- and re-use holes made by deleted records
   -- =================================================
   -- what is the system area min and max"?"
   set @sql1 = 'select  @uidMin = UIDMIN,@uidMax = UIDMAX,@sysMin = SYSID_MIN,@sysMax = SYSID_MAX  from DICTLOOK where
                TABLENAME = ''' + ltrim(rtrim(@aTableName)) + ''''
   execute sp_executesql @sql1,N'@uidMin int output,@uidMax int output,@sysMin int output,@sysMax int output',@uidMin output,@uidMax output,@sysMin output,@sysMax output

   if(@sysFlag = 0)
   begin
      -- Alias.FieldName not between @sysMin and @sysMax
      set @whereClause = ' not between  '+rtrim(ltrim(str(@sysMin)))+'- 1 and '+rtrim(ltrim(str(@sysMax)))
      set @whereClause = @whereClause+ char(10) + ' and x1.'+@idField+' >= '+rtrim(ltrim(str(@uidMin)))
   end
   else
   begin
      -- system id, Alias.FieldName between @sysMin and @sysMax
      set @whereClause = ' between  '+rtrim(ltrim(str(@sysMin)))+' and '+rtrim(ltrim(str(@sysMax)))+'- 1 '
      set @whereClause = @whereClause+ char(10) + ' and x1.'+@idField+' >= '+rtrim(ltrim(str(@sysMin)))
   end
   -- =================================================
   -- if countryID needed, new ID is highest within the country
   -- =================================================
   if not @countryID = ''
   begin
      -- append COUNTRY_ID = 'countryID' filter
      set @whereClause = @whereClause+ char(10) + ' and x1.COUNTRY_ID = '+''''+@countryID+''''
   end
   -- =================================================
   -- Find any gap in a sequence of numbers.
   -- SDG__00010642 Start from UIDMIN
   -- =================================================
   if(@sysFlag = 0)
   begin
	set @sql1 = 'select @newID = isnull(min(x1.'+@idField+' + 1),@uidMin) '+ char(10) + 'from '+rtrim(ltrim(@aTableName))+' x1 left outer join '+rtrim(ltrim(@aTableName))+' x2 ' + char(10) + '   on x1.'+rtrim(ltrim(@idField))+'+1 = x2.'+rtrim(ltrim(@idField))+' ' + char(10) + 'where x2.'+rtrim(ltrim(@idField))+' is null and x1.'+rtrim(ltrim(@idField))+@whereClause
	execute sp_executesql @sql1, N'@newID int output,@uidMin int',@newID output,@uidMin
   end
   else
   begin
	set @sql1 = 'select @newID = isnull(min(x1.'+@idField+' + 1),@sysMin) '+ char(10) + 'from '+rtrim(ltrim(@aTableName))+' x1 left outer join '+rtrim(ltrim(@aTableName))+' x2 ' + char(10) + '   on x1.'+rtrim(ltrim(@idField))+'+1 = x2.'+rtrim(ltrim(@idField))+' ' + char(10) + 'where x2.'+rtrim(ltrim(@idField))+' is null and x1.'+rtrim(ltrim(@idField))+@whereClause
	execute sp_executesql @sql1, N'@newID int output,@sysMin int',@newID output,@sysMin
   end
   if @display > 1
   begin
	print '================================='
	execute absp_MessageEx @sql
	print '================================='
   end

   if(@sysFlag = 0)
   begin
	if @newID < @uidMin
	begin
		set @newID = @uidMin
	end
   end
   else
   begin
	if @newID < @sysMin
	begin
	    set @newID = @sysMin
        end
   end
   set @sql1 = 'select @cnt = count(*) from '+rtrim(ltrim(@aTableName))+ ' where '+ rtrim(ltrim(@idField))+ ' = '+ rtrim(ltrim(str(@newID)))
   if @display > 1
   begin
	  print '================================='
	  execute absp_MessageEx @sql
	  print '================================='
   end

   execute sp_executesql @sql1, N'@cnt int output',@cnt output

   -- if we are already using that newID, then check the upper user range
   if @cnt > 0
   begin
	  set @whereClause = ' between  1+'+rtrim(ltrim(str(@sysMax)))+' and '+rtrim(ltrim(str(@uidMax)))
	  set @sql1 = 'select @newID = isnull(min(x1.'+@idField+' + 1), @sysMax + 1) ' + char(10) + 'from '+rtrim(ltrim(@aTableName))+' x1 left outer join '+rtrim(ltrim(@aTableName))+' x2 ' + char(10) + '   on x1.'+rtrim(ltrim(@idField))+'+1 = x2.'+rtrim(ltrim(@idField))+' ' + char(10) + 'where x2.'+rtrim(ltrim(@idField))+' is null and x1.'+rtrim(ltrim(@idField))+@whereClause
	  if @display > 1
	  begin
		 print '================================='
		 execute absp_MessageEx @sql
		 print '================================='
	  end
	execute sp_executesql @sql1, N'@newID int output,@sysMax int',@newID output,@sysMax
   end
   set @sql1 = 'select @cnt = count(*) from '+rtrim(ltrim(@aTableName))+' where '+rtrim(ltrim(@idField))+' = '+rtrim(ltrim(str(@newID)))
   if @display > 1
   begin
	  print '================================='
	  execute absp_MessageEx @sql
	  print '================================='
   end
   execute sp_executesql @sql1, N'@cnt int output',@cnt output

   if @cnt > 0 or @newID >= @uidMax
   begin
	  print '@cnt = '+rtrim(ltrim(str(@cnt)))+'  @uidMax = '+rtrim(ltrim(str(@uidMax)))
	  print 'table '+rtrim(ltrim(@aTableName))+' is full.   No more '+rtrim(ltrim(@idField))+' are available.'
	  return -1
   end
   if @display <> 0
   begin
	  print 'new id = '+rtrim(ltrim(str(@newID)))+' for table '+rtrim(ltrim(@aTableName))+' , field '+rtrim(ltrim(@idField))
   end

   -- insert a new record in the lookup using the @newID and (when needed) the country
   --  For all tables except D0410 (schema table), add a dummy TRANS_ID of -1
   --  example:  insert into RLOBL ( R_LOB_ID, COUNTRY_ID, TRANS_ID ) values ( 9405, 'ZAF', -1 )
   set @transIdCol = ' , TRANS_ID '
   set @transIdVal = ' , -1 '
   if @aTableName = 'D0410'
   begin
      set @transIdCol = ''
      set @transIdVal = ''
   end
   if not @countryID = ''
   begin
      set @klist = rtrim(ltrim(@aTableName)) +' ( '+rtrim(ltrim(@idField))+', COUNTRY_ID '+rtrim(@transIdCol)
      set @vlist = ' values '+'( '+rtrim(ltrim(str(@newID)))+', '+''''+@countryID+''''+rtrim(@transIdVal)
   end
   else
   begin
      set @klist = rtrim(ltrim(@aTableName))+' ( '+rtrim(ltrim(@idField)) + rtrim(@transIdCol)
      set @vlist = ' values ( '+rtrim(ltrim(str(@newID)))+ rtrim(@transIdVal)
   end

   -- add default values for non-null fields to the insert list to satisfy SQL Server requirement
   declare curs1 cursor fast_forward global for select FIELDNAME, FIELDTYPE from DICTCOL d join DICTTBLX dx on d.TABLENAME=dx.TABLENAME and dx.TYPE not in ('a', 'p') and dx.tablename not in('TIL', 'STATEL')
	where NULLABLE ='N' and FIELDNAME !='TRANS_ID' and d.TABLENAME = rtrim(ltrim(@aTableName)) and FIELDNAME != rtrim(ltrim(@idField))

	open curs1
	fetch next from curs1 into @fieldName,@fieldType
	while @@fetch_status = 0
	begin
	    set @klist = @klist + ', ' + ltrim(rtrim(@fieldName))
	    if ltrim(rtrim(@fieldType)) = 'C'
	    	set @vlist = @vlist + ', '''''
	    else
	    	set @vlist = @vlist + ', -1'

            fetch next from curs1 into @fieldName,@fieldType
	end
	close curs1
	deallocate curs1

   -- create insert statement
   set @sql1 = 'insert into '+ @klist + ') ' + @vlist + ')'

   --print @sql1
   execute(@sql1)
   return(@newID)
end