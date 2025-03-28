if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_TableCloneRecords') and objectproperty(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_Migr_TableCloneRecords
end
go

create procedure absp_Migr_TableCloneRecords
	@myTableName varchar(1000),
	@skipKeyFieldNum int,
	@whereClause varchar(max),
	@fieldValueTrios varchar(max),
	@linkedSvrName varchar(200)='',
	@sourceDBName varchar(130),
	@targetDBName varchar(130)=''
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    	MSSQL

Purpose:	This procedure clones records of a table, based on the given Where Clause.

Returns:    	@theIdentity = value of the last autogenerating key from the temporary table

====================================================================================================

</pre>
</font>
##BD_END

##PD   @myTableName 	^^ Name of a table for which record cloning has to be done.
##PD   @skipKeyFieldNum	^^ Field name that has to be skipped (0 --> not to skipped , any other number of the field that has to be skipped)
##PD   @whereClause 	^^ Record cloning criteria.
##PD   @fieldValueTrios ^^ Format, how to change field name in the temporary table created from the base table. This format has to be in accordance to the expected parameter of procodure "absp_StringSetFields"
##RD   @linkedSvrName ^^ Linked server name for target DB Name
##RD   @sourceDBName ^^ Source db
##RD   @targetDBName ^^ TargetDB


*/
as
begin

	set nocount on

	declare @fieldNames varchar(8000)
	declare @replNames varchar(max)
	declare @sql nvarchar(max)
	declare @debugFlag int
	declare @theIdentity int
	declare @colname varchar(2000)
	declare @msgText varchar(255)
	declare @keyfld int
	declare @HasIdentity int
	declare @uName varchar(25)
	declare @gName varchar(25)
	declare @where varchar(8000)
	declare @uKey int
	declare @gKey int
	declare @tabStep varchar(2)

	set @debugFlag = 1;
	set @HasIdentity =-1
	if @targetDBName ='' set @targetDBName =DB_NAME()
	
	-- get the table field names from dictcol
	execute absp_Migr_DataDictGetFields @fieldNames output,@myTableName,@skipKeyFieldNum 
		
	-- replace those filled with overrides from user
	execute absp_StringSetFields @replNames output, @fieldNames, @fieldValueTrios;
	
	/*--Check if we have any new Users or Groups----------------------
	if right(@myTableName,4)='Info'
	begin
		if (CHARINDEX('Create_By',@replNames)>0)
		begin
			set @sql='select  @uName=User_Name from  '+ @linkedSvrName+'.[' + @sourceDBName + '].dbo.' + @myTableName + 
					' t inner join '+ @linkedSvrName+'.[' + @sourceDBName + '].dbo.UserInfo u on 
					t.Create_By=u.User_Key'
			if @debugFlag =1 exec absp_Messageex @sql
			execute sp_executesql @sql,N'@uName varchar(25) output',@uName output
			--Add UserInfo row
			if not exists(select 1 from UserInfo where User_Name=@uName)
			begin
				set @where='User_Name=''' + @uName +''''
				exec @uKey=absp_Migr_TableCloneRecords 'UserInfo',1,@where,'',@linkedSvrName,@sourceDBName,'commondb'
				set @fieldValueTrios=@fieldValueTrios+ @tabStep+'int'+@tabStep+'Create_By'+@tabStep+cast(@uKey as varchar(20))
			end
		end
		if (CHARINDEX('Group_Key',@replNames)>0)
		begin
			set @sql='select @gName=Group_Name from  '+ @linkedSvrName+'.[' + @sourceDBName + '].dbo.' + @myTableName + 
					' t inner join '+ @linkedSvrName+'.[' + @sourceDBName + '].dbo.UserGrps g on
					t.Group_Key=g.Group_Key'
			if @debugFlag =1 exec absp_Messageex @sql
			execute sp_executesql @sql,N'@gName varchar(25) output',@gName output
			
			--Add UserGrps row
			if not exists(select 1 from UserGrps where Group_Name=@gName)
			begin
				set @where='Group_Name=''' + @gName +''''
				exec @gKey=absp_Migr_TableCloneRecords 'UserGrps',1,@where,'',@linkedSvrName,@sourceDBName,'commondb'
				set @fieldValueTrios= @fieldValueTrios+@tabStep+'int'+@tabStep+'Group_key'+@tabStep+cast(@gKey as varchar(20))
		end
	end
	-- replace those filled with overrides from user
	execute absp_StringSetFields @replNames output, @replNames, @fieldValueTrios;
	end
	--------------------------------------------------------------------*/
	
	set @sql =  ' insert into ['+ @targetDBName + '].dbo.' + dbo.trim(@myTableName) +' ( '+@fieldNames+' )'+
			' select  '+@replNames+' from  '+ @linkedSvrName+'.[' + @sourceDBName + '].dbo.' + @myTableName;
	if @whereClause<> '' set @sql = @sql + ' mt   where mt.'+@whereClause;


	if(@debugFlag > 0)execute absp_MessageEx @sql;

	execute(@sql)

	if @@rowcount>0
	begin
		select  @theIdentity = IDENT_CURRENT (dbo.trim(@myTableName))
	end

	return COALESCE(@theIdentity, 0);
end
