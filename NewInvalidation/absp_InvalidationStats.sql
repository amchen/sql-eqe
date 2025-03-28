if exists(select * from SYSOBJECTS where ID = object_id(N'absp_InvalidationStats') and objectproperty(id,N'IsProcedure') = 1)
begin
   drop procedure absp_InvalidationStats;
end
go

create procedure absp_InvalidationStats @NodeKey int, @nodeType integer
/*
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure counts the invalidation table records. Enter the NodeKey, NodeType.

Returns: This returns the table recordcounts of the Parents, Children, and Self Node deleted by
Invalidation.

====================================================================================================

*/
as
begin
declare @InvalidationList varchar(max)
declare @InvalidationListIR varchar(max)
declare @ErrMessage nvarchar(500)
declare @ErrMessage2 nvarchar(500)
declare @ErrMessage3 nvarchar(max)
declare @MyStr varchar(max)
declare @curTable varchar(300)
declare @sqlCur varchar(max)
declare @MyStrALL varchar(max)
declare @MyExpALL varchar(max)
declare @dbName varchar(max)
declare @irDBName varchar(max)
declare @keyColumn varchar(max)
declare @keyList varchar(max)
declare @cursNodeKey int
declare @cursNodeType int
declare @TopLvl nvarchar(max)
declare @err int
declare @InfoTable varchar(50)
declare @ExposureKey int

	set @MyStrAll=''
	set @MyExpAll=''
	set @TopLvl=''
	set @err=1

	set @dbName =DB_NAME();
	exec absp_getDBName  @dbName out, @dbName, 0; -- Enclose within brackets--

	if RIGHT(rtrim(@dbName),4) != '_IR]'
		exec absp_getDBName  @irDBName out, @dbName, 1;
	else
		set @irDBName = @dbName;

	--sanity check
	if (@nodeType NOT in(1,2,23,27,30))
		begin
		set @ErrMessage= N'%s';
			RAISERROR (@ErrMessage, 16, 1,'Invalid @nodeType passed!');
			return
        end

		select @InfoTable = Case @nodeType
			when 1  then 'aprtinfo'
			when 2  then 'pprtinfo'
			when 23 then 'rprtinfo'
			when 27 then 'proginfo'
			when 30 then 'caseinfo' end

			if (@NodeType=1)	set @keyColumn='APORT_KEY'
			if (@NodeType=2)	set @keyColumn='PPORT_KEY'
			if (@NodeType=23)	set @keyColumn='RPORT_KEY'
			if (@NodeType=27)	set @keyColumn='PROG_KEY'
			if (@NodeType=30)	set @keyColumn='CASE_KEY'

	select @ErrMessage3='select @err=count(*) from '+@InfoTable+' where '+@keyColumn+'='+dbo.trim(str(@NodeKey))
		 execute sp_executesql @ErrMessage3,N'@err int output',@err output

	if (@err=0)
		begin
		set @ErrMessage= N'%s';
		set @ErrMessage2='Use a valid combination of Key and Type dude!!'
		select @sqlCur=ParentKey, @MyStr=ParentType from ExposureMap
		set @ErrMessage2=@ErrMessage2+' TRY @NodeKey='+dbo.trim(@sqlCur)+', @nodeType='+dbo.trim(@MyStr)
			RAISERROR (@ErrMessage, 16, 1,@ErrMessage2);
			return
        end

	--create temp table to populate in absp_PopulateChildList
	create table #NODELIST (NODE_KEY INT, NODE_TYPE INT, PARENT_KEY INT, PARENT_TYPE INT);

	--create temp table to populate ExposureSets
	create table #ExposureList (EXPOSUREKEY INT);

	--get all parent nodes
	execute absp_PopulateParentList @nodeKey, @nodeType;

	--get all child nodes
  	execute absp_PopulateChildList @nodeKey, @nodeType;

	--insert the current node
	insert #NODELIST (NODE_KEY,NODE_TYPE) values (@nodeKey,@nodeType);


	declare curs2  cursor DYNAMIC  for
		SELECT distinct n.NODE_KEY,n.NODE_TYPE FROM [#NODELIST] n order by n.NODE_TYPE desc
			open curs2
			fetch next from curs2 into @cursNodeKey,@cursNodeType
			while @@fetch_status = 0
			begin

		    if (@cursNodeType=0)    break;
			if (@cursNodeType=1)	select @InvalidationList='Inv.Aport.Res', @InvalidationListIR='', @keyColumn='APORT_KEY'
			if (@cursNodeType=2)	select @InvalidationList='Inv.Pport.Res', @InvalidationListIR='Inv.Pport.IR.Res', @keyColumn='PPORT_KEY'
			if (@cursNodeType=23)	select @InvalidationList='Inv.RPort.Res', @InvalidationListIR='Inv.RPort.IR.Res', @keyColumn='RPORT_KEY'
			if (@cursNodeType=27)	select @InvalidationList='Inv.Program.Res', @InvalidationListIR='Inv.Program.IR.Res', @keyColumn='PROG_KEY'
			if (@cursNodeType=30)	select @InvalidationList='Inv.Treaty.Res', @InvalidationListIR='Inv.Treaty.IR.Res', @keyColumn='CASE_KEY'

			--loop through Primary Side tables
			set @sqlCur='select TABLENAME from dbo.absp_Util_GetTableList('''+@InvalidationList+''')'
			execute('declare MyCursor cursor global for '+ @sqlCur);
			--print @sqlCur
			open MyCursor
			fetch next from MyCursor into @curTable
			while @@fetch_status = 0
				begin
				--print 'TableName: '+@curTable
				 set @MyStr = 'select '+dbo.trim(str(@cursNodeKey))+' as NODEKEY,'+dbo.trim(str(@cursNodeType))
				 +' as NODETYPE,''PRI'' as ''DBLOC'','''+dbo.trim(@curTable)+''' as ''TABLE'', count(*) as ''RCOUNT'','''+@keyColumn+'='
				 + dbo.trim(str(@cursNodeKey))+'''as ''QUERY'' from '+dbo.trim(@curTable)
				 +' where ' +@keyColumn+'='+dbo.trim(str(@cursNodeKey))+' union '
				 select @MyStrALL=@MyStrALL+' '+dbo.trim(@MyStr)
				 fetch next from MyCursor into @curTable
				end
			close MyCursor
			deallocate MyCursor

			--loop through IR tables
			set @sqlCur='select TABLENAME from dbo.absp_Util_GetTableList('''+@InvalidationListIR+''')'
			execute('declare MyCursor cursor global for '+ @sqlCur);
			open MyCursor
			fetch next from MyCursor into @curTable
			while @@fetch_status = 0
				begin
					if (@cursNodeType=27)
						if (@curTable='ExpPolA')
							begin
								set @keyColumn='PROGRAMKEY'
							end
							else
							if (@curTable='INTRDONEA')
								begin
									set @keyColumn='EXPOSUREKEY'
								end
								else
									set @keyColumn='PROG_KEY';

				 set @MyStr = 'select '+dbo.trim(str(@cursNodeKey))+' as NODEKEY,'+dbo.trim(str(@cursNodeType))
				 +' as NODETYPE,''_IR'' as ''DBLOC'','''+dbo.trim(@curTable)+''' as ''TABLE'', count(*) as ''RCOUNT'','''
				 +@keyColumn+'='+dbo.trim(str(@cursNodeKey))+''' as ''QUERY'' from '+@irDBName+'..'+dbo.trim(@curTable)
				 +' where '+@keyColumn+'='+dbo.trim(str(@cursNodeKey))+' union '
				 select @MyStrALL=@MyStrALL+' '+dbo.trim(@MyStr)
				 fetch next from MyCursor into @curTable
				end
			close MyCursor
			deallocate MyCursor

		--loop through EXPOSURE tables
		insert #ExposureList select ExposureKey from exposuremap where ParentKey=@cursNodeKey and ParentType=@cursNodeType


		fetch next from curs2 into @cursNodeKey,@cursNodeType
		end
	close curs2
	deallocate curs2

			declare MyExpCursor cursor for
				select distinct EXPOSUREKEY from #ExposureList;
			open MyExpCursor
			fetch next from MyExpCursor into @exposurekey
			while @@fetch_status = 0
				begin
					declare MyCursor cursor for
						select TABLENAME from dbo.absp_Util_GetTableList('Inv.Exp.Res')
							open MyCursor
							fetch next from MyCursor into @curTable
							while @@fetch_status = 0
								begin
									set @MyStr = 'select '+dbo.trim(str(@exposurekey))+' as EXPOSUREKEY,''PRI'' as ''DBLOC'','''+dbo.trim(@curTable)+''' as ''TABLE'', count(*) as ''RCOUNT'', ''ExposureKey='
									 + dbo.trim(str(@exposurekey))+'''as ''QUERY'' from '+dbo.trim(@curTable)
									 +' where ExposureKey='+dbo.trim(str(@exposurekey))+' union '
									 select @MyExpALL=@MyExpALL+' '+dbo.trim(@MyStr)
								 fetch next from MyCursor into @curTable
							end
						close MyCursor
						deallocate MyCursor

						declare MyCursor cursor for
						select TABLENAME from dbo.absp_Util_GetTableList('Inv.Exp.IR.Res')
							open MyCursor
							fetch next from MyCursor into @curTable
							while @@fetch_status = 0
								begin
									set @MyStr = 'select '+dbo.trim(str(@exposurekey))+' as EXPOSUREKEY,''_IR'' as ''DBLOC'','''+dbo.trim(@curTable)+''' as ''TABLE'', count(*) as ''RCOUNT'', ''ExposureKey='
									 + dbo.trim(str(@exposurekey))+'''as ''QUERY'' from '+dbo.trim(@curTable)
									 +' where ExposureKey='+dbo.trim(str(@exposurekey))+' union '
									 select @MyExpALL=@MyExpALL+' '+dbo.trim(@MyStr)
								 fetch next from MyCursor into @curTable
							end
						close MyCursor
						deallocate MyCursor
			fetch next from MyExpCursor into @exposurekey
			end
			close MyExpCursor
			deallocate MyExpCursor


set @TopLvl=N''+left(@MyStrAll,len(@MyStrAll)-5)
set @MyExpALL=N''+left(@MyExpALL,len(@MyExpALL)-5)
--print (@TopLvl)
execute (@TopLvl)
execute (@MyExpALL)
--SELECT distinct n.NODE_KEY,n.NODE_TYPE FROM [#NODELIST] n order by n.NODE_TYPE desc
end
--absp_InvalidationStats @NodeKey=1, @nodeType=1
--absp_InvalidationStats @NodeKey=1, @nodeType=2
--absp_InvalidationStats @NodeKey=1, @nodeType=23
--absp_InvalidationStats @NodeKey=1, @nodeType=27
--absp_InvalidationStats @NodeKey=1, @nodeType=30