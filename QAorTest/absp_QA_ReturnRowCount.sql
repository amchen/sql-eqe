if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_QA_ReturnRowCount') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_QA_ReturnRowCount
end
 go

create procedure absp_QA_ReturnRowCount
as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
=================================================================================
Purpose:       The procedure will return the recordcount for all the tables 
				so as to check the process of deletion/invalidation. 

Returns:       None.
=================================================================================
</pre>
</font>
##BD_END
*/

begin  
	set nocount on
	declare @tableName varchar(120);
	declare @sql varchar(max);
	declare @columnName varchar(120);
	
	create table #TmpTbl (TableName varchar(130) COLLATE SQL_Latin1_General_CP1_CI_AS, RecordCount int );

	declare  curs  cursor for select tableName from #TblList A inner join  Sysobjects B on A.TableName=B.Name
	open curs
	fetch curs into @tableName
	while @@FETCH_STATUS =0
	begin
	print @tableName
		if (@tableName in (select TABLENAME from dbo.absp_Util_GetTableList('Inv.Rport.IR.Res')))
			set @columnName='Rport_Key'
		else if (@tableName in (select TABLENAME from dbo.absp_Util_GetTableList('Inv.Pport.IR.Res')))
			set @columnName='Pport_Key'
		else if (@tableName in (select TABLENAME from dbo.absp_Util_GetTableList('Inv.Treaty.IR.Res')))
			set @columnName='Case_Key'
		else if (@tableName in (select TABLENAME from dbo.absp_Util_GetTableList('Inv.Exp.IR.Res')))
			set @columnName='ExposureKey'
		else if (@tableName in (select TABLENAME from dbo.absp_Util_GetTableList('Inv.Program.Dmg.IR.Res')) and @tableName not in('IntrDoneA'))
		begin
			if @tableName='ExpPolA'
			begin
				set @columnName='ProgramKey'
			end
			else 
			begin
				set @columnName='PROG_KEY'
			end
		end
		else if (@tableName in (select TABLENAME from dbo.absp_Util_GetTableList('Inv.Program.IR.Res')))
			set @columnName='PROG_KEY'
		else
			set @columnName=''

		set @sql='insert into #TmpTbl select ''' + @tableName + ''',COUNT(*) from ' + @tableName 
		if @columnName <>''
			set @sql=@sql+ ' where ' + @columnName + '>=0';
		print @sql
		exec(@sql)

		fetch curs into @tableName
	end
	close curs
	deallocate curs	
	select * from #TmpTbl
end