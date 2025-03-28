if exists(select 1 from SYSOBJECTS where ID = object_id(N'absp_TreeviewExposureCleanup') and OBJECTPROPERTY(ID,N'IsProcedure') = 1)
begin
   drop procedure absp_TreeviewExposureCleanup
end
go

create procedure absp_TreeviewExposureCleanup @nodeKey int, @nodeType int , @ParentKey int=-1, @ParentType int=-1, @exposureKey int = 0, @targetDbName varchar(120) = ''
as

/*
##BD_BEGIN
<font size ="3">
<pre style="font-family: Lucida Console;" >
====================================================================================================
Purpose:    This procedure deletes all ExposureMap related to the nodeKey and nodeType, parentype, parentKey
Returns:    Nothing.
Example:    exec absp_TreeviewExposureCleanup 1, 2, 1,0
====================================================================================================
</pre>
	</font>
##BD_END

##PD  @NodeKey   ^^  The node type for the requested report.
##PD  @NodeType  ^^  The node key for the requested report.
##PD  @parentKey   ^^  The parent node key of the cleanup node
##PD  @parentType  ^^  The parent node type for the cleanup node.
##PD  @exposureKey  ^^  The specific key for the cleanup node. if exposureKey <=0, clean up the map
*/

begin try
--declare @targetDBName varchar(max) ='',@nodekey int=1,@nodetype int=0
	declare @sqlQuery nvarchar(max)
	declare @dbName  varchar(130)
	declare @exposure_Key int,@i int, @cnt int
	declare @cursExposureKey int
	declare @cursNodeKey int
	declare @cursNodeType int
	declare @cursParentKey int
	declare @cursParentType int 
	declare @expClause varchar(max)
	declare @delExpRecFolder int
	declare @delExpRecAport int
	declare @delExpRecRport int
	declare @delExpRec int

	--when deleting an exposureset an exposureKey will be sent from Java.
	set @expClause=''
	set @delExpRecFolder=0
	set @delExpRecAport=0
	set @delExpRecRport=0
	set @delExpRec=0
	if @exposureKey>0 begin	set @expClause=' AND @dbName..ExposureMap.ExposureKey='+ rtrim(str(@exposureKey)) end;
	
	set @sqlQuery = '';
	if @targetDBName = ''
		set @dbName = DB_NAME();
	else
		set @dbName = @targetDBName;

	--Enclose within square brackets--
	execute absp_getDBName @dbName out, @dbName;

	--drop table #NODELIST
	--create temp table to populate in absp_PopulateChildList
	create table #NODELIST (NODE_KEY INT, NODE_TYPE INT, PARENT_KEY INT, PARENT_TYPE INT);

	--get all child nodes of the cleanup node and populate #NODELIST
  	execute absp_PopulateChildList @nodeKey, @nodeType;
	
	--insert the current cleanup node
	insert #NODELIST (NODE_KEY,NODE_TYPE,PARENT_KEY,PARENT_TYPE) values (@nodeKey,@nodeType,@ParentKey,@ParentType);

	--create temp table to store all specific clean up commands
	create table #NODECLEANUP (CleanupID INT identity, CleanupStmnt varchar(2000));
	--narrow for exposurekeys of interest
	declare curs2  cursor DYNAMIC  for
		SELECT distinct n.NODE_KEY,n.NODE_TYPE,n.PARENT_KEY,n.PARENT_TYPE FROM [#NODELIST] n order by n.NODE_TYPE desc
			open curs2
			fetch next from curs2 into @cursNodeKey,@cursNodeType,@cursParentKey,@cursParentType
			while @@fetch_status = 0
			begin
			if (@cursParentType=0)--Check for a Folder PasteLink
				select @delExpRecFolder=COUNT(*) from FLDRMAP where Child_Key=@cursNodeKey AND Child_Type=@cursNodeType;
			if (@cursParentType=1)--Check for an Aport PasteLink
				select @delExpRecAport=COUNT(*) from APORTMAP where Child_Key=@cursNodeKey AND Child_Type=@cursNodeType;
			if (@cursParentType=23)--Check for a Rport PasteLink
				select @delExpRecRport=COUNT(*) from RPORTMAP where Child_Key=@cursNodeKey AND Child_Type=@cursNodeType;
			set @delExpRec = @delExpRecFolder + @delExpRecAport + @delExpRecRport 
			--Only delete exposuremap record when there is only 1 record in the map table
			--OR if an ExposureKey is passed in(for deleting specific exposuresets).										
			if (@delExpRec=1 and (@cursNodeType=2 or @cursNodeType=27)) or (@exposureKey>0) 
				begin	
					--add 'delete ExposureMap' statements to the #NodeCleanup table
					set @sqlQuery = 'delete from @dbName..ExposureMap where ParentKey= ' + rtrim(str(@cursNodeKey)) + ' and ParentType = ' + rtrim(str(@cursNodeType)) + @expClause;
					set @sqlQuery = replace(@sqlQuery, '@dbName',   @dbName);
					insert into #NODECLEANUP values(@sqlQuery);
					--execute sp_executesql @sqlQuery;

				end
			
			-- exposureKey <=0 means that we want to delete a node and we have to clean up the map in this case
			if (@exposureKey <= 0)
			begin
				-- add 'delete map' statements to the #NodeCleanup table
				-- add to the deletemap if the node is the actual deleted node OR
				-- there are no paste links for the node
				if (@delExpRec=1) or (@nodeKey = @cursNodeKey and @nodeType = @cursNodeType 
					and @parentKey = @cursParentKey and @parentType=@cursParentType) 
				begin
					if (@cursParentType=0) 
					insert into #NODECLEANUP values( 'delete from FLDRMAP where Child_Key=' + rtrim(str(@cursNodeKey)) + ' and Child_Type=' + rtrim(str(@cursNodeType)) + ' and Folder_Key=' + rtrim(str(@cursParentKey)) );

					if (@cursParentType=1) 
					insert into #NODECLEANUP values( 'delete from APORTMAP where Child_Key=' + rtrim(str(@cursNodeKey)) + ' and Child_Type=' + rtrim(str(@cursNodeType)) + ' and Aport_Key=' + rtrim(str(@cursParentKey)) );

					if (@cursParentType=23) 
					insert into #NODECLEANUP values( 'delete from RPORTMAP where Child_Key=' + rtrim(str(@cursNodeKey)) + ' and Child_Type=' + rtrim(str(@cursNodeType)) + ' and Rport_Key=' + rtrim(str(@cursParentKey)) );
				end
			end
			--reset
			set @delExpRecFolder=0
			set @delExpRecAport=0
			set @delExpRecRport=0
			set @delExpRec=0
			fetch next from curs2 into @cursNodeKey,@cursNodeType,@cursParentKey,@cursParentType;
	end
	close curs2;
	deallocate curs2;

	-- loop through the #nodecleanup table to do the specific cleanups
	declare curs3  cursor DYNAMIC  for
		SELECT CleanupStmnt from #NODECLEANUP
		open curs3
		fetch next from curs3 into @sqlQuery
		while @@fetch_status = 0
		begin         
			execute sp_executesql @sqlQuery;
			fetch next from curs3 into @sqlQuery
		end
		close curs3;
		deallocate curs3;
	
	--delete orphan ExposureKeys
	set @sqlQuery = 'delete @dbName..ExposureMap where ExposureKey not in (select ExposureKey from @dbName..ExposureInfo)';
	set @sqlQuery = replace(@sqlQuery, '@dbName',   @dbName);
	execute sp_executesql @sqlQuery;

end try

begin catch
	declare @ProcName varchar(100);
	select @ProcName=object_name(@@procid);
	exec absp_Util_GetErrorInfo @ProcName;
end catch