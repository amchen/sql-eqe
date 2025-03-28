if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_Migr_CreateTreeHierarchy') and objectproperty(ID,N'isprocedure') = 1)
begin
   drop procedure absp_Migr_CreateTreeHierarchy
end

go

create procedure absp_Migr_CreateTreeHierarchy @nodeKey int, @nodeType int ,@linkedServer varchar(120)='',@sourceDB varchar(120)=''

as
/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
DB Version:    MSSQL
Purpose:

This procedure populates #TMPTREE table with the parent node details of the given node.


Returns:       Nothing
====================================================================================================
</pre>
</font>
##BD_END

##PD  @nodeKey    ^^ The key of the node whose parent nodes are to be determined
##PD  @nodeType   ^^ The type of the node whose parent nodes are to be determined

*/
begin
	set nocount on;
	declare @parentKey int;
	declare @parentType int;
	declare @sName varchar(2000);
	declare @sql nvarchar(max);
	declare @currKey int;
	declare @debug int;

	set @debug=0;

	if @linkedServer=''
		set @sName='';
	else
		set @sName=@linkedServer + '.[' +@sourceDB + '].dbo.';

	--Get the parent node key and type--
	--There can be multiple parents in case of PasteLink for Pport,Rport, Program
	create table #TmpTbl(NodeKey int ,NodeType int,ParentKey int,ParentType int);

	-- Fix converted nodeTypes
	if (@nodeType=3)  set @nodeType=23;
	if (@nodeType=7)  set @nodeType=27;
	if (@nodeType=10) set @nodeType=30;

	if @nodeType=0 or @nodeType=1 or @nodeType=2 or @nodeType=23
	begin
		set @sql='insert into #TmpTbl(NodeKey,NodeType,ParentKey,ParentType)
			 select ' + cast(@nodeKey as varchar(20))+ ','+ cast(@nodeType as varchar(20)) +
			',Folder_Key,0 from ' + @sName + 'FldrMap where Child_Key='+cast(@nodeKey as varchar(20))+
			' and Child_Type = '+ cast(@nodeType as varchar(20));
		if @debug =1 exec absp_MessageEx @sql;
 		exec (@sql);

		set @sql='insert into #TmpTbl(NodeKey,NodeType,ParentKey,ParentType)
			select   ' + cast(@nodeKey as varchar(20))+ ','+ cast(@nodeType as varchar(20)) +
			',Aport_Key,1 from ' + @sName + 'AportMap where Child_Key='+cast(@nodeKey as varchar(20))+
			' and Child_Type = '+ cast(@nodeType as varchar(20));
		if @debug =1 exec absp_MessageEx @sql;
 		exec (@sql);
	end
	else if @nodeType=27
	begin

		set @parentType=23;

		set @sql='insert into #TmpTbl(NodeKey,NodeType,ParentKey,ParentType)  ' +
			' select ' + cast(@nodeKey as varchar(20))+ ','+ cast(@nodeType as varchar(20)) +
			',Rport_Key,'+cast(@parentType as varchar(20))+' from ' + @sName + 'RportMap
			 where Child_Key='+ cast(@nodeKey as varchar(20)) + ' and Child_Type= '+ cast(@nodeType as varchar(20));

		if @debug =1 exec absp_MessageEx @sql;
 		exec (@sql);

		--insert cases for prog--
		set @sql='insert into #TmpTbl (NodeKey,NodeType,ParentKey,ParentType)
					select CASE_KEY, 30, PROG_KEY, 27
					from '  + @sName + 'CASEINFO
				where PROG_KEY =' + cast(@nodeKey as varchar);
		if @debug =1 exec absp_MessageEx @sql;
 		exec (@sql);
 	end

	insert into #TMPTREE(NodeKey,NodeType,ParentKey,ParentType) select NodeKey,NodeType,ParentKey,ParentType from #TmpTbl;

	--Call procedure for each parent--
	declare c1 cursor for select distinct ParentKey,ParentType from  #TmpTbl 
					where ParentType<>27 order by parentType desc -- Cases have been picked up
	open c1
	fetch c1 into @parentKey,@parentType
	while @@FETCH_STATUS=0
	begin

		--Check if we have reached the  parent currency folder
		set @sql='select @currKey=folder_Key from ' + @sName + 'FldrInfo where Curr_Node=''Y'''
		execute  sp_executesql @sql,N'@currKey int output',@currKey output
		if @parentKey=@currKey and @parentType=0 return

		exec absp_Migr_CreateTreeHierarchy @parentKey,@parentType,@linkedServer,@sourceDB
		fetch c1 into @parentKey,@parentType


	end
	close c1
	deallocate c1

end